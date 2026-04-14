module Seek
  # Provides text and PDF extraction methods for ContentBlob used in search indexing.
  # All file I/O is routed through the storage adapter so both local and S3 backends work.
  module ContentExtraction
    include ContentTypeDetection
    include SysMODB::SpreadsheetExtractor
    include ContentSplit

    def pdf_contents_for_search
      content = []
      if file_exists?
        if is_pdf?
          # Pattern B: write the dat content directly to the pdf key via adapter.
          storage_adapter('pdf').write(storage_key('pdf'), data_io_object)
        elsif is_pdf_convertable?
          convert_to_pdf
        end
        content = extract_text_from_pdf
        if content.blank?
          []
        else
          content = filter_text_content content
          content = split_content(content, 10, 5)
        end
      else
        Rails.logger.info("No local file contents for content blob #{id}, so no pdf contents for search available")
      end
      content
    end

    def text_contents_for_search
      content = []
      if file_exists?
        # Pattern A: read via adapter IO; force encoding to match original File.read behaviour.
        text = data_io_object.read.force_encoding('iso-8859-1')
        unless text.blank?
          content = filter_text_content text
          content = split_content(content, 10, 5)
        end
      end
      content
    end

    # Converts the blob to PDF and stores the result via the storage adapter.
    # No-ops if the pdf key already exists.
    def convert_to_pdf
      adapter_convert_to_pdf
    end

    def extract_text_from_pdf
      return '' unless is_pdf? || is_pdf_convertable?
      # Pattern B: check whether the PDF exists in the adapter, not on the local filesystem.
      return '' unless storage_adapter('pdf').exist?(storage_key('pdf'))

      begin
        # Pattern C: if TXT not yet extracted, run Docsplit via a local PDF copy and write back.
        unless storage_adapter('txt').exist?(storage_key('txt'))
          with_temporary_copy_of_converted('pdf') do |local_pdf_path|
            Dir.mktmpdir('docsplit-txt') do |tmp_dir|
              Docsplit.extract_text(local_pdf_path, output: tmp_dir)
              txt_path = Dir["#{tmp_dir}/*.txt"].first
              storage_adapter('txt').write(storage_key('txt'), File.open(txt_path, 'rb')) if txt_path
            end
          end
        end

        # Pattern B: read extracted text back through the adapter.
        return '' unless storage_adapter('txt').exist?(storage_key('txt'))

        storage_adapter('txt').open(storage_key('txt')).read
      rescue Docsplit::ExtractionFailed => e
        Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
        ''
      end
    end

    def to_csv(sheet = 1, trim = false)
      return '' unless is_excel?

      sheet = resolve_sheet_name_to_index(sheet) if sheet && !sheet.to_s.match(/\A[0-9]*\z/)
      # SysMODB's IO path writes binary data to a text-mode Tempfile, causing an
      # encoding error on binary XLS/XLSX content. Always pass a file path instead.
      with_dat_path { |path| spreadsheet_to_csv(path, sheet, trim, Seek::Config.jvm_memory_allocation) }
    end

    def extract_csv
      # Pattern A: read via adapter IO.
      data_io_object.read
    end

    def to_spreadsheet_xml
      # SysMODB's IO path writes binary data to a text-mode Tempfile, causing an
      # encoding error on binary XLS/XLSX content. Always pass a file path instead.
      with_dat_path { |path| spreadsheet_to_xml(path, Seek::Config.jvm_memory_allocation) }
    end

    private

    # Adapter-based PDF conversion. Called by convert_to_pdf when no explicit paths
    # are provided. Downloads the dat file to a local temp copy, runs Libreconv, and
    # uploads the resulting PDF back through the adapter.
    #
    # NOTE: the exist? guard is a TOCTOU race — two concurrent jobs can both see the
    # PDF absent and both start converting. The race is harmless (last write wins, both
    # produce identical output). Fixing it requires distributed locking — out of scope.
    def adapter_convert_to_pdf
      return if storage_adapter('pdf').exist?(storage_key('pdf'))

      Rails.logger.info("Converting blob #{id} to pdf")
      file_ext = mime_extensions(content_type).first

      with_temporary_copy do |dat_path|
        Tempfile.create(['converted', '.pdf']) do |pdf_tmp|
          tmp_dat = Tempfile.new(['', ".#{file_ext}"])
          begin
            FileUtils.cp(dat_path, tmp_dat.path)
            Libreconv.convert(tmp_dat.path, pdf_tmp.path)
            Rails.logger.info("Finished converting blob #{id} to pdf")
            pdf_tmp.rewind
            storage_adapter('pdf').write(storage_key('pdf'), pdf_tmp)
          ensure
            tmp_dat.close!
          end
        end
      end
    rescue StandardError => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data: { content_blob: self, asset: asset })
      Rails.logger.error("Problem with converting file of content_blob #{id} to pdf - #{e.class.name}:#{e.message}")
    end


    def resolve_sheet_name_to_index(sheet_name)
      doc = LibXML::XML::Parser.string(to_spreadsheet_xml).parse
      doc.root.namespaces.default_prefix = 'ss'
      doc.find('//ss:sheet').each do |sheet|
        return sheet['index'] if sheet['name'] == sheet_name
      end
      raise SysMODB::SpreadsheetExtractionException, 'Unrecognised sheet name'
    end

    # filters special characters, keeping alphanumeric characters, hyphen ('-'), underscore('_') and newlines
    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, ' ')
    end

    # Yields a guaranteed local filesystem path to the dat file.
    # For local storage the real on-disk path is yielded directly.
    # For S3 the file is copied to a temp location first, then cleaned up.
    def with_dat_path(&block)
      local = storage_adapter.full_path(storage_key)
      if local
        block.call(local)
      else
        with_temporary_copy(&block)
      end
    end
  end
end
