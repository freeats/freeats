# frozen_string_literal: true

class CVParser::Content
  PHONE_REGEX = /[+]*(?:[-()\u00a0\d]\s{0,2}){5,}/
  EMAIL_REGEX = /[^@\s\u00a0]+@[^@\s\u00a0]+/
  URL_REGEX = %r{(?:https?://)?(?:\w+\.)+(?:[a-zA-Z]{2,4})(?:[/\w.?%=:-]*)/?}
  DEFAULT_COUNTRY_CODE = ENV.fetch("COUNTRY_CODE_FOR_PHONE_PARSING", nil)

  attr_reader :phones, :emails, :urls

  def initialize(phones, emails, urls)
    @phones = phones
    @emails = emails
    @urls = urls
  end

  class << self
    def extract_from_text(text, country_code:)
      country_code ||= DEFAULT_COUNTRY_CODE
      phones =
        text
        .scan(PHONE_REGEX)
        .each_with_object([]) do |phone, memo|
          phone.strip!
          next unless Phonelib.valid?(phone)

          ph = parse_phone(phone, country_code)
          country_code = ph.country_code if ph&.country_code
          memo << ph.e164
        end

      emails = text.scan(EMAIL_REGEX).each_with_object([]) do |email, memo|
        email = email.strip.sub(/[[:punct:]]+\z/, "")
        next unless Person.valid_email?(email)

        memo << { address: email }
      end

      email_based_urls = emails.flat_map { |email| email[:address].split("@") }

      urls = text.scan(URL_REGEX).each_with_object([]) do |url, memo|
        url.strip!
        next if email_based_urls.include?(url)

        begin
          url = Addressable::URI.heuristic_parse(url).to_s
        rescue Addressable::URI::InvalidURIError
          next
        end
        url.chop! if url.ends_with?(".")
        next if !valid_url?(url) || AccountLink.new(url).blacklisted?

        memo << url
      end
      new(phones.uniq, emails.uniq, urls.uniq(&:downcase))
    end

    private

    def parse_phone(phone, country_code)
      if Phonelib.valid_for_country?(phone, country_code)
        Phonelib.parse(phone, country_code)
      elsif country_code.present? && Phonelib.valid?(country_code + phone)
        Phonelib.parse(country_code + phone)
      else
        Phonelib.parse(phone)
      end
    end

    def valid_url?(url)
      parsed_url = Addressable::URI.parse(url)
      PublicSuffix.valid?(parsed_url.hostname, default_rule: nil) &&
        # Escape codes for @.
        !parsed_url.hostname.match?(/%2540|%40/) &&
        # Top level domain names usually have no upper-case letters.
        !parsed_url.hostname.split(".").last.match?(/[A-Z]/)
    rescue Addressable::URI::InvalidURIError
      false
    end
  end
end
