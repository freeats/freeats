# frozen_string_literal: true

module CVParser
  class CVParserError < StandardError; end
  class UnsupportedFileType < CVParserError; end

  class Parser
    class << self
      def parse(file)
        case File.extname(file)
        when ".pdf" then parse_pdf(file)
        when ".docx" then parse_docx(file)
        else
          raise UnsupportedFileType
        end
      end

      private

      def parse_pdf(file)
        reader = PDF::Reader.new(file)
        reader.pages.reduce("") { |text, page| text + page.text }
      end

      def parse_docx(file)
        Docx::Document.open(file).text
      end
    end
  end
end
