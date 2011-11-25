module Seek

  #FIXME: needs consolidating with SpreadsheetUtil
  class SpreadsheetHandler
    include SpreadsheetUtil
    include Seek::MimeTypes
    include SysMODB::SpreadsheetExtractor
    
    def contents_for_search data_file
      begin
        xml=data_file.spreadsheet_xml
        if !xml.nil?
          return extract_content(xml)
        end
      rescue Exception=>e
        Rails.logger.error("Error processing spreadsheet for content_blob #{data_file.content_blob_id}",e)
      end

      []
      
    end

    #pulls out all the content from cells into an array
    def extract_content xml
      content=[]
      doc = LibXML::XML::Parser.string(xml).parse
      doc.root.namespaces.default_prefix="ss"
      doc.find("//ss:sheet").each do |sheet|
        unless sheet["hidden"] == "true" || sheet["very_hidden"] == "true"
          sheet.find("//ss:cell").each do |cell|
            content << cell.content
          end
        end
      end
      content
    end

  end


end