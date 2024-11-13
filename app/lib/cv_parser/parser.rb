# frozen_string_literal: true

module CVParser
  class CVParserError < StandardError; end
  class UnsupportedFileType < CVParserError; end

  class Parser
    def self.parse_pdf(file)
      reader = PDF::Reader.new(file)
      reader.pages.reduce("") { |text, page| text + page.text }
    end
  end
end
