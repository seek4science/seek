module DoiQueryToolExtension

  DoiRecord.class_eval do
    attr_accessor :citation

    def initialize_with_extension(attributes={})
      initialize_without_extension attributes
      self.citation = attributes[:citation]
    end

    alias_method_chain :initialize, :extension

  end

  DoiQuery.class_eval do
    def parse_xml_with_extension(article)
          doi_record = parse_xml_without_extension(article)
          begin
            #bug fix for empty/missing book title
            doi_record.journal ||= article.find_first("//book_metadata/titles/title").try(&:content)
            # add citation
            if article.find_first('//journal_metadata/abbrev_title')
              citation_iso_abbrev = article.find_first('//journal_metadata/abbrev_title').content
            elsif article.find_first('//title')
              citation_iso_abbrev = article.find_first('//title').content
            else
              citation_iso_abbrev = ""
            end
            citation_volume = article.find_first('.//volume') ? article.find_first('.//volume').content : ""
            citation_issue = article.find_first('.//issue') ? "(" + article.find_first('.//issue').content + ")" : ""
            citation_first_page = article.find_first('.//first_page') ? " : " + article.find_first('.//first_page').content : ""
            doi_record.citation = citation_iso_abbrev + " " + citation_volume + citation_issue + citation_first_page

            return doi_record
          rescue Exception => e
            return DoiRecord.new({:error => "Unable to process the DOI metadata: #{e.message}"})
          end
    end

    alias_method_chain :parse_xml, :extension
  end


end