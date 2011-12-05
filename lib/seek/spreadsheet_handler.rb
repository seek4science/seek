module Seek

  #FIXME: needs consolidating with SpreadsheetUtil
  class SpreadsheetHandler
    include SpreadsheetUtil
    include Seek::MimeTypes
    include SysMODB::SpreadsheetExtractor
    
    def contents_for_search data_file
      content = Rails.cache.fetch("#{data_file.content_blob.cache_key}-SS-XML") {
        begin
          xml=data_file.spreadsheet_xml
          if !xml.nil?
            content = extract_content(xml)
            content = humanize_content(content)
            content = filter_content(content)
            content
          else
            []
          end
        rescue Exception=>e
          Rails.logger.error("Error processing spreadsheet for content_blob #{data_file.content_blob_id} #{e}")
        end
      }

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

    #does some manipulation of the content, e.g. converting camelcase and converting underscores, whilst preserving the original
    #form
    def humanize_content content
      content.collect do |val|
        [content,val.underscore.humanize.downcase]
      end.flatten.uniq
    end

    #filters out numbers and text declared in a black list
    def filter_content content
      blacklist = ["seek id"] #not yet defined
      content = content - blacklist
      content.reject do |val|
        val.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
      end
    end

  end


end