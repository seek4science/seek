module Seek
  module ContentExtraction
    include ContentTypeDetection
    include SysMODB::SpreadsheetExtractor
    include ContentSplit

    # Extracts text from a PDF file stored in S3 via Shrine
    def pdf_contents_for_search
      return [] unless stored_in_shrine?

      content = []
      if is_pdf? || is_pdf_convertable?
        shrine_file.download do |temp_file|
          if is_pdf_convertable? && !is_pdf?
            # Convert non-PDF files to PDF
            convert_to_pdf(temp_file.path)
          end

          content = extract_text_from_pdf(temp_file.path)
          if content.present?
            content = filter_text_content(content)
            content = split_content(content, 10, 5)
          end
        end
      end

      content
    end

    # Extracts text content from text-based files stored via Shrine
    def text_contents_for_search
      return [] unless stored_in_shrine?

      content = []
      shrine_file.download do |temp_file|
        text = File.read(temp_file.path, encoding: "iso-8859-1")
        unless text.blank?
          content = filter_text_content(text)
          content = split_content(content, 10, 5)
        end
      end
      content
    end

    # Converts a file to PDF format using Shrine-based storage
    def convert_to_pdf(temp_file_path)
      Rails.logger.info("Converting file to PDF using temporary path: #{temp_file_path}")
      pdf_path = "#{temp_file_path}.pdf"

      begin
        Libreconv.convert(temp_file_path, pdf_path)
        Rails.logger.info("Finished converting file to PDF")
      rescue StandardError => e
        Seek::Errors::ExceptionForwarder.send_notification(e, data: { content_blob: self, asset: asset })
        Rails.logger.error("Failed PDF conversion: #{e.class.name}: #{e.message}")
      end

      pdf_path
    end

    # Extracts text content from an existing PDF file stored via Shrine
    def extract_text_from_pdf(temp_pdf_path)
      begin
        txt_filepath = "#{temp_pdf_path}.txt"
        Docsplit.extract_text(temp_pdf_path, output: File.dirname(txt_filepath)) unless File.exist?(txt_filepath)
        File.read(txt_filepath)
      rescue Docsplit::ExtractionFailed => e
        Rails.logger.error("Failed to extract text from PDF: #{e.class.name}: #{e.message}")
        ''
      end
    end

    def to_csv(sheet = 1, trim = false)
      return '' unless is_excel?
      sheet = resolve_sheet_name_to_index(sheet) if (sheet && !sheet.to_s.match(/\A[0-9]*\z/))

      shrine_file.download do |temp_file|
        spreadsheet_to_csv(temp_file.path, sheet, trim, Seek::Config.jvm_memory_allocation)
      end
    end

    def extract_csv
      return shrine_file.download { |io| io.read } if stored_in_shrine?
      # currently we only consider S3 storage via Shrine, in the future we can add other storage methods if needed
      raise "File does not exist in S3 storage"
    end

    def to_spreadsheet_xml
      shrine_file.download do |temp_file|
        spreadsheet_to_xml(temp_file.path, Seek::Config.jvm_memory_allocation)
      end
    end

    private

    def resolve_sheet_name_to_index(sheet_name)
      shrine_file.download do |temp_file|
        doc = LibXML::XML::Parser.string(spreadsheet_to_xml(temp_file.path)).parse
        doc.root.namespaces.default_prefix = 'ss'
        doc.find('//ss:sheet').each do |sheet|
          return sheet['index'] if sheet['name'] == sheet_name
        end
      end

      raise SysMODB::SpreadsheetExtractionException, 'Unrecognized sheet name'
    end

    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, ' ')
    end
  end
end