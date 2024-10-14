# frozen_string_literal: true

module Imap
  Message = Data.define(
    :message_id,
    :imap_uid,
    :timestamp,
    :flags, # https://datatracker.ietf.org/doc/html/rfc9051#name-flags-message-attribute
    :to,
    :from,
    :cc,
    :bcc,
    :subject,
    :plain_body,
    :plain_mime_type,
    :html_body,
    :attachments,
    :x_failed_recipients,
    :in_reply_to,
    :references,
    :headers,
    :autoreply_headers
  ) do
    self::NAME_AND_ADDRESS_REGEX = /^(?:['"]?\\?['"]?([^<]*[^'"\\])\\?['"]{0,2}\s)?<([^>]+)>$/i
    class << self
      # @return [Enumerator] with args [Array<Imap::Message>] messages
      # containing `target_emails` in `from_account`.
      # @param target_emails [Array<String>] emails that are queried for.
      # @param from_account [Imap::Account] account which are queried from.
      # @param batch_size [Integer] maximum number of messages which will be fetched per request.
      def message_batches_related_to(
        target_emails,
        from_account:,
        batch_size: Imap::Account::DEFAULT_BATCH_SIZE
      )
        Enumerator.new do |y|
          loop do
            messages = from_account.fetch_all_messages_related_to(
              target_emails,
              batch_size:
            )
            y << messages

            break if messages.size < batch_size
          end
        end
      end

      # @return [Enumerator] with args [Array<Imap::Message>] messages containing
      # updates from `from_account`.
      # @param from_account [Imap::Account] account which are queried from.
      # @param batch_size [Integer] maximum number of messages which will be fetched per request.
      def new_message_batches(
        from_account:,
        batch_size: Imap::Account::DEFAULT_BATCH_SIZE
      )
        Enumerator.new do |y|
          fetch_messages_method =
            if from_account.last_email_synchronization_uid.present?
              lambda do |batch_size|
                from_account.fetch_updates(
                  batch_size:
                )
              end
            else
              lambda do |batch_size|
                from_account.fetch_messages_for_last(
                  10.days.ago,
                  batch_size:
                )
              end
            end

          loop do
            messages = fetch_messages_method.call(batch_size)
            y << messages

            break if messages.size < batch_size
          end
        end
      end

      # @param message [Mail]
      # @param uid [Integer] imap's uid
      def new_from_api(message, uid, flags)
        if message.mime_type == "application/pkcs7-mime"
          decoded_message = OpenSSL::PKCS7.new(Base64.decode64(message.body.raw_source))

          unless decoded_message.verify([], OpenSSL::X509::Store.new, nil, OpenSSL::PKCS7::NOVERIFY)
            extra = {
              imap_uid: uid,
              timestamp: message.date.to_i,
              to: message[:to]&.formatted || [],
              from: message[:from]&.formatted || [],
              cc: message[:cc]&.formatted || [],
              bcc: message[:bcc]&.formatted || []
            }

            Log.tagged("Imap::Message#new_from_api") do |log|
              log.error("Decoded pkcs7 message is not verified.", **extra)
            end
          end

          Mail.new(decoded_message.data).parts.each do |part|
            message.parts << part
          end
        end

        begin
          plain_body = message.text_part&.decoded || ""
        rescue Mail::UnknownEncodingType
          plain_body = message.text_part&.encoded || ""
        end

        plain_body_charset = message.text_part&.charset
        plain_mime_type = message.text_part&.mime_type || ""

        begin
          html_body = message.html_part&.decoded || ""
        rescue Mail::UnknownEncodingType
          html_body = message.html_part&.encoded || ""
        end

        html_body_charset = message.html_part&.charset

        # Message can be without multiple parts.
        # Only messages with Content-Type: multipart/alternative; have parts.
        if message.parts.blank?
          message_mime_type = message.mime_type || ""

          if message_mime_type.include?("html")
            html_body = message.body&.decoded
            html_body_charset = message.charset
          else
            plain_mime_type = message_mime_type
            plain_body = message.body&.decoded
            plain_body_charset = message.charset
          end
        end

        fix_encoding(plain_body, plain_body_charset)
        fix_encoding(html_body, html_body_charset)

        new(
          message_id:
            message.header_fields.filter { _1.name.casecmp("message-id").zero? }.first.value,
          imap_uid: uid,
          timestamp: message.date.to_i,
          flags: flags.map(&:to_s),
          to: message[:to]&.formatted || [],
          from: message[:from]&.formatted || [],
          cc: message[:cc]&.formatted || [],
          bcc: message[:bcc]&.formatted || [],
          subject: message.subject || "",
          plain_body: plain_body || "",
          plain_mime_type: plain_mime_type || "",
          html_body: html_body || "",
          attachments: message.attachments,
          x_failed_recipients: extract_header(message, "x-failed-recipients"),
          in_reply_to:
            message.header_fields.filter { _1.name.casecmp("in-reply-to").zero? }.first&.value,
          references:
            message.header_fields.filter { _1.name.casecmp("references").zero? }.map(&:value),
          headers: message.header_fields.map { { _1.name => _1.value } }, # For debug
          autoreply_headers: {
            auto_submitted: extract_header(message, "auto-submitted"),
            x_autoreply: extract_header(message, "x-autoreply"),
            x_autorespond: extract_header(message, "x-autorespond"),
            precedence: extract_header(message, "precedence"),
            x_precedence: extract_header(message, "x-precedence"),
            x_auto_response_suppress: extract_header(message, "x-auto-response-suppress")
          }
        )
      rescue Mail::UnknownEncodingType, Encoding::UndefinedConversionError => e
        extra = {
          imap_uid: uid,
          timestamp: message.date.to_i,
          to: message[:to]&.formatted || [],
          from: message[:from]&.formatted || [],
          cc: message[:cc]&.formatted || [],
          bcc: message[:bcc]&.formatted || []
        }

        Log.tagged("Imap::Message#new_from_api") do |log|
          log.error(e, **extra)
        end

        nil
      end

      def parse_address(address)
        name, email_address = address.match(self::NAME_AND_ADDRESS_REGEX)&.captures || ["", address]
        { name: name&.strip || "", address: email_address&.strip }
      end

      private

      def fix_encoding(body, message_charset)
        return if body.blank? || message_charset.blank? || body.encoding == Encoding::UTF_8

        charset = message_charset.downcase.gsub(/[^(\w\-_)]/, "")

        return if charset == Account::DEFAULT_SEARCH_CHARSET.downcase

        picked_encoding = Mail::Utilities.pick_encoding(charset)

        body.encode!(Account::DEFAULT_SEARCH_CHARSET, picked_encoding)
      end

      def extract_header(message, name)
        header = message.header_fields.find { _1.name.casecmp(name).zero? }
        header.blank? ? "" : header.value
      end

      def extract_addresses(message, header)
        h = message.header_fields.find { _1.name.casecmp(header.to_s).zero? }&.value
        return [] if h.nil?

        h.split(",").filter { |addr| addr.include?("@") }.map(&:strip)
      end
    end

    def encoded
      mail = ::Mail.new(
        from:,
        to:,
        cc:,
        subject:,
        body: html_body,
        content_type: "text/html",
        charset: "UTF-8"
      )
      if in_reply_to.present?
        mail.header["In-Reply-To"] = in_reply_to
        mail.header["References"] = references
      end
      mail.encoded
    end

    def present_emails
      to + from + cc + bcc
    end

    def clean_from_emails
      from.map { self.class.parse_address(_1)[:address] }
    end

    def clean_to_emails
      to.map { self.class.parse_address(_1)[:address] }
    end

    def clean_cc_emails
      cc.map { self.class.parse_address(_1)[:address] }
    end

    def clean_bcc_emails
      bcc.map { self.class.parse_address(_1)[:address] }
    end

    def clean_present_emails
      present_emails.map { self.class.parse_address(_1)[:address] }
    end

    # Hash object without large fields that can be used for debugging.
    def to_debug_hash
      to_h.except(:plain_body, :html_body, :attachments)
    end

    def from_mail_service?
      daemon_usernames_regex = EmailMessage::DAEMON_USERNAMES.join("|")
      daemons_addresses = EmailMessage::MAIL_SERVICE_ADDRESSES.map { Regexp.escape(_1) }.join("|")
      from.any?(/#{daemon_usernames_regex}.*@|\A#{daemons_addresses}\z/i)
    end

    def to_mail_service?
      daemons_addresses = EmailMessage::MAIL_SERVICE_ADDRESSES.map { Regexp.escape(_1) }.join("|")
      to.any?(/#{daemons_addresses}\z/i)
    end

    def failed_delivery?
      (x_failed_recipients.present? || auto_replied?) && from_mail_service? &&
        subject.match?(EmailMessage::DELIVERY_INCOMPLETE_SUBJECTS_REGEX)
    end

    def find_unsuccessful_delivery_reason
      return nil unless failed_delivery?

      reason_title =
        plain_body.match(EmailMessage::GMAIL_DELIVERY_INCOMPLETE_REASON_REGEX)&.[](1) ||
        plain_body[EmailMessage::OUTLOOK_DELIVERY_INCOMPLETE_REASONS_REGEX]
      EmailMessage::DELIVERY_INCOMPLETE_REASONS[reason_title] || "failed"
    end

    def auto_replied?
      return false if autoreply_headers.blank?

      autoreply_headers[:auto_submitted].in?(%w[auto-replied auto-generated]) ||
        autoreply_headers[:x_autoreply] == "yes" ||
        autoreply_headers[:x_auto_response_suppress] == "OOF" ||
        autoreply_headers[:precedence].in?(%w[bulk auto_reply junk]) ||
        autoreply_headers[:x_precedence].in?(%w[bulk auto_reply junk]) ||
        autoreply_headers[:x_autorespond] == "yes"
    end
  end
end
