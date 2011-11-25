module Seek

  #FIXME: needs consolidating with SpreadsheetUtil
  class SpreadsheetHandler
    include SpreadsheetUtil
    include Seek::MimeTypes
    include SysMODB::SpreadsheetExtractor
    
    def contents_for_search data_file
      content = Rails.cache.fetch("cell-contents-for-#{data_file.content_blob_id}")
      return content if !content.nil?
      begin
        xml=data_file.spreadsheet_xml
        if !xml.nil?
          content = extract_content(xml)
        end
      rescue Exception=>e
        Rails.logger.error("Error processing spreadsheet for content_blob #{data_file.content_blob_id} #{e}")
      end
      Rails.cache.write("cell-contents-for-#{data_file.content_blob_id}",content)
      content || []
    end

    #pulls out all the content from cells into an array
    def extract_content xml
      
      doc = LibXML::XML::Parser.string(xml).parse
      doc.root.namespaces.default_prefix="ss"

      content = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell").collect do |cell|
        cell.content
      end
      
      content
    end

  end


end