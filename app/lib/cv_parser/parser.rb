# frozen_string_literal: true

module CVParser
  class CVParserError < StandardError; end
  class UnsupportedFileType < CVParserError; end

  class Parser
    class << self
      def parse_pdf(file)
        reader = PDF::Reader.new(file)
        plain_text = reader.pages.reduce("") { |text, page| "#{text} #{page.text}" }
        links = reader.pages.flat_map do |page|
          Array(page.attributes[:Annots]).flat_map do |annotation|
            process_annotations(page, annotation)
          end
        end.uniq.compact
        urls = links.grep(/^http/i)
        email_links = links.grep(/^mailto:/i)
        emails = email_links.map { _1.sub(/^mailto:/i, "") }
        if (extra_links = links - urls - email_links).present?
          Log.tagged("CVParser::parse_pdf") { _1.warn(extra_links:) }
        end

        { plain_text:, urls:, emails: }
      end

      def retrieve_plain_text_from_pdf(file)
        reader = PDF::Reader.new(file)
        reader.pages.reduce("") { |text, page| text + page.text }
      end

      private

      def process_annotations(page, obj)
        case obj
        when PDF::Reader::Reference
          process_annotations(page, page.objects[obj])
        when Array
          obj.filter_map { |o| process_annotations(page, o) }
        when Hash
          return nil if obj[:Subtype] != :Link || !obj.key?(:A)

          case obj[:A]
          when PDF::Reader::Reference
            case uri_obj = page.objects[obj[:A]][:URI]
            when String
              uri_obj
            when PDF::Reader::Reference
              page.objects[uri_obj]
            else
              Log.tagged("CVParser::process_annotations") do |log|
                log.external_log("uri_obj is not a string or a reference", obj:)
              end
              nil
            end
          when Hash
            obj[:A][:URI]
          else
            Log.tagged("CVParser::process_annotations") do |log|
              log.external_log("obj[:A] is not a reference or hash", obj:)
            end
            nil
          end
        else
          Log.tagged("CVParser::process_annotations") do |log|
            log.external_log("obj is not a reference, array or hash", obj:)
          end
          nil
        end
      end
    end
  end
end
