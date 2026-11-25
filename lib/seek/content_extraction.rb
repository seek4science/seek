module Seek
  module ContentExtraction
    include ContentTypeDetection
    include SysMODB::SpreadsheetExtractor
    include ContentSplit

    UTF8_CHECK_CHUNK_SIZE = 1024 * 1024

    def pdf_contents_for_search
      content = []
      if file_exists?
        if is_pdf?
          # copy .dat to .pdf
          FileUtils.cp filepath, filepath('pdf')
        elsif is_pdf_convertable?
          convert_to_pdf
        end
        content = extract_text_from_pdf
        if content.blank?
          []
        else
          content = filter_text_content content
          content = split_content(content, 10 , 5)
        end
      else
        Rails.logger.info("No local file contents for content blob #{id}, so no pdf contents for search available")
      end
      content
    end

    def text_contents_for_search
      content = []
      if file_exists?
        text = File.read(filepath, encoding: 'iso-8859-1')
        unless text.blank?
          content = filter_text_content text
          content = split_content(content,10,5)
        end
      end
      content
    end

    def convert_to_pdf(dat_filepath = filepath, pdf_filepath = filepath('pdf'))
      unless File.exist?(pdf_filepath)
        Rails.logger.info("Converting blob #{id} to pdf")
        # copy dat file to original file extension in order to convert to pdf on this file
        file_extension = mime_extensions(content_type).first
        tmp_file = Tempfile.new(['', '.' + file_extension])
        copied_filepath = tmp_file.path

        FileUtils.cp dat_filepath, copied_filepath

        Libreconv.convert(copied_filepath, pdf_filepath)

        Rails.logger.info("Finished converting blob #{id} to pdf")

      end
    rescue StandardError => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data: { content_blob: self, asset: asset })
      Rails.logger.error("Problem with converting file of content_blob #{id} to pdf - #{e.class.name}:#{e.message}")
    end

    def extract_text_from_pdf
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')

      return '' unless is_pdf? || is_pdf_convertable?
      return '' unless File.exist?(pdf_filepath)

      begin
        Docsplit.extract_text(pdf_filepath, output: converted_storage_directory) unless File.exist?(txt_filepath)
        File.read(txt_filepath)
      rescue Docsplit::ExtractionFailed => e
        Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
        ''
      end

    end

    def to_csv(sheet = 1, trim = false)
      return '' unless is_excel?
      sheet = resolve_sheet_name_to_index(sheet) if (sheet && !sheet.to_s.match(/\A[0-9]*\z/))
      spreadsheet_to_csv(filepath, sheet, trim, Seek::Config.jvm_memory_allocation)
    end

    # Opens the file as UTF-8 text, yielding the IO to the block. Some CSV files are not UTF-8
    # (e.g. ISO-8859-1/Latin-1), which would cause CSV parsing to raise CSV::InvalidEncodingError, so
    # if the bytes aren't valid UTF-8 they are read as ISO-8859-1 and transcoded to UTF-8 as they are
    # read. Unlike reading the whole file into a String, this never holds the full contents in memory.
    def open_as_utf8(&block)
      mode = valid_utf8_file? ? 'r:UTF-8' : 'r:ISO-8859-1:UTF-8'
      File.open(filepath, mode, &block)
    end

    # Checks the file is valid UTF-8, reading it in chunks rather than all at once
    def valid_utf8_file?(chunk_size = UTF8_CHECK_CHUNK_SIZE)
      File.open(filepath, 'rb') do |file|
        pending = ''.b
        while (chunk = file.read(chunk_size))
          pending = valid_utf8_prefix_remainder(pending << chunk)
          return false if pending.nil?
        end
        pending.empty?
      end
    end

    def to_spreadsheet_xml
      spreadsheet_to_xml(filepath, Seek::Config.jvm_memory_allocation)
    end

    private

    # A chunk may end part way through a multi-byte character. Returns the trailing bytes (at most 3) of
    # an incomplete character, to be prepended to the next chunk, or nil if the data is not valid UTF-8.
    def valid_utf8_prefix_remainder(data)
      (0..3).each do |tail|
        break if tail > data.bytesize
        prefix = data.byteslice(0, data.bytesize - tail).force_encoding(Encoding::UTF_8)
        return data.byteslice(data.bytesize - tail, tail) if prefix.valid_encoding?
      end
      nil
    end

    def resolve_sheet_name_to_index(sheet_name)

      doc = LibXML::XML::Parser.string(to_spreadsheet_xml).parse
      doc.root.namespaces.default_prefix = 'ss'
      doc.find('//ss:sheet').each do |sheet|
        if sheet['name'] == sheet_name
          return sheet['index']
        end
      end
      raise SysMODB::SpreadsheetExtractionException.new('Unrecognised sheet name')
    end


    # filters special characters, keeping alphanumeric characters, hyphen ('-'), underscore('_') and newlines
    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, ' ')
    end
  end
end
