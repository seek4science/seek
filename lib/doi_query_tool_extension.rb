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
            citation_iso_abbreviation = article.find_first('.//ISOAbbreviation') ? article.find_first('.//ISOAbbreviation').content : ""
            citation_year = article.find_first('.//PubDate/Year') ? article.find_first('.//PubDate/Year').content : ""
            citation_month = article.find_first('.//Month') ? article.find_first('.//Month').content : ""
            citation_volume = article.find_first('.//Volume') ? article.find_first('.//Volume').content : ""
            citation_issue = article.find_first('.//Issue') ? "(" + article.find_first('.//Issue').content + ")" : ""
            citation_med_line_pgn = article.find_first('.//MedlinePgn') ? article.find_first('.//MedlinePgn').content : ""
            doi_record.citation = citation_iso_abbreviation + " " + citation_year + " " + citation_month + ", " + citation_volume + citation_issue + " : " + citation_med_line_pgn

            return doi_record
          rescue Exception => e
            return DoiRecord.new({:error => "Unable to process the DOI metadata: #{e.message}"})
          end
    end

    alias_method_chain :parse_xml, :extension
  end


end