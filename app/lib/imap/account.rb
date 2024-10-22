# frozen_string_literal: true

require "mail"
require "net/imap"

class Imap::Account
  IMAP_ADDRESS = "imap.gmail.com"
  IMAP_PORT = 993

  AUTHORIZATION_RETRY_DELAY = 1.second
  DEFAULT_BATCH_SIZE = 100
  DEFAULT_SEARCH_CHARSET = "UTF-8"
  DEFAULT_MAILBOX = "[Gmail]/All Mail"
  DATE_FORMAT = "%d-%b-%Y"
  # https://www.rfc-editor.org/rfc/rfc3501#page-8
  MAX_UID = 4_294_967_295

  class AuthError < Net::IMAP::Error; end

  attr_reader :imap_service, :status, :logger

  # Variables necessary for init imap service.
  attr_reader :email, :access_token, :refresh_token, :imap_address, :imap_port

  # UID from member, using for continue sync emails.
  attr_reader :last_email_synchronization_uid

  # UID for fetching emails by batches.
  attr_reader :last_message_uid

  def initialize(
    email:,
    access_token:,
    refresh_token:,
    imap_address: IMAP_ADDRESS,
    imap_port: IMAP_PORT,
    last_email_synchronization_uid: nil
  )
    @email = email
    @access_token = access_token
    @refresh_token = refresh_token
    @imap_address = imap_address
    @imap_port = imap_port
    @last_email_synchronization_uid = last_email_synchronization_uid

    @imap_service = init_imap_service
    @logger = ATS::Logger.new(where: "Imap::Account::@email=#{email}")
  end

  # Get authenticated imap service.
  def init_imap_service
    retries ||= 0
    authentication = Gmail::Auth.with_tokens(
      @access_token || "",
      @refresh_token || ""
    )
    # Try to catch Webmock errors about external requests.
    raise if Rails.env.test? && authentication.class != Minitest::Mock

    authentication.fetch_access_token!

    Mail::IMAP.new(
      address: @imap_address,
      port: @imap_port,
      enable_ssl: true,
      authentication: "XOAUTH2",
      user_name: @email,
      password: authentication.access_token
    )
  rescue Signet::AuthorizationError
    if (retries += 1) < 5
      sleep AUTHORIZATION_RETRY_DELAY
      retry
    end

    nil
  end

  def search(
    query,
    batch_size: DEFAULT_BATCH_SIZE
  )
    raise AuthError if @imap_service.blank?

    retries ||= 0
    messages = []
    uid_range =
      @last_message_uid ? ["UID", "#{@last_message_uid + 1}:#{MAX_UID}"] : []

    # It is needed to filter out unsent messages and with draft label.
    # https://developers.google.com/gmail/imap/imap-extensions#extension_of_the_search_command_x-gm-raw
    gmail_query = ["X-GM-RAW", "(in:anywhere -in:draft -in:scheduled -label:draft)"]

    @imap_service.find(
      mailbox: DEFAULT_MAILBOX,
      keys: query + uid_range + gmail_query,
      search_charset: DEFAULT_SEARCH_CHARSET,
      read_only: true,
      count: batch_size
    ) do |fetched_message, _imap, uid, flags|
      message = Imap::Message.new_from_api(fetched_message, uid, flags)
      messages << message if message
    end

    @status = :succeeded
    @last_message_uid = messages.map(&:imap_uid).max if messages.present?

    messages
  rescue OpenSSL::SSL::SSLError, Net::OpenTimeout,
         Errno::ECONNRESET, Socket::ResolutionError
    @status = :network_issues
    []
  rescue AuthError
    @status = :unauthenticated
    []
  # Sometimes the mail server returns an empty response
  # and the mail library gets NoMethodError.
  rescue Net::IMAP::ResponseError, NoMethodError => e
    if (retries += 1) < 3
      sleep AUTHORIZATION_RETRY_DELAY
      @imap_service = init_imap_service
      retry
    end

    @status = e.message.include?("Invalid credentials") ? :unauthorized : :failure

    Log.tagged("Imap::Account#search") do |log|
      log.error(e, email:)
    end

    []
  end

  # @param date [Date] mails will be searched from this date inclusive.
  def fetch_messages_for_last(
    date,
    batch_size: DEFAULT_BATCH_SIZE
  )
    search(
      ["SENTSINCE", date.strftime(DATE_FORMAT)],
      batch_size:
    )
  end

  def fetch_all_messages_related_to(
    target_emails,
    batch_size: DEFAULT_BATCH_SIZE
  )
    search_query = []

    target_emails.each do |email|
      search_query.push(
        "OR", "TO", email, "OR", "FROM", email, "OR", "CC", email, "BCC", email
      )
    end
    search(search_query, batch_size:)
  end

  def fetch_updates(
    batch_size: DEFAULT_BATCH_SIZE
  )
    @last_message_uid = @last_email_synchronization_uid if @last_message_uid.nil?
    search([], batch_size:)
  end

  def fetch_messages_by_uid(imap_uids)
    search(["UID", Array(imap_uids).join(",")])
  end

  def fetch_message_by_id(header_message_id)
    search(["HEADER", "Message-ID", header_message_id]).first
  end
end
