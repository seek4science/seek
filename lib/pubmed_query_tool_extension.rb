module PubmedQueryToolExtension
  PubmedRecord.class_eval do
    attr_accessor :citation

    def initialize_with_extension(attributes={})
      initialize_without_extension(attributes)
      self.citation = attributes[:citation]
    end

    alias_method_chain :initialize, :extension
  end

  PubmedQuery.class_eval do
    def parse_article_with_extension article
      pubmed_record = parse_article_without_extension(article)
      begin
        citation_iso_abbreviation = article.find_first('.//ISOAbbreviation') ? article.find_first('.//ISOAbbreviation').content : ""
        citation_year = article.find_first('.//PubDate/Year') ? article.find_first('.//PubDate/Year').content : ""
        citation_month = article.find_first('.//Month') ? article.find_first('.//Month').content : ""
        citation_volume = article.find_first('.//Volume') ? article.find_first('.//Volume').content : ""
        citation_issue = article.find_first('.//Issue') ? "(" + article.find_first('.//Issue').content + ")" : ""
        citation_med_line_pgn = article.find_first('.//MedlinePgn') ? article.find_first('.//MedlinePgn').content : ""
        pubmed_record.citation = citation_iso_abbreviation + " " + citation_year + " " + citation_month + ", " + citation_volume + citation_issue + " : " + citation_med_line_pgn

        return pubmed_record
      rescue Exception => e
        return PubmedRecord.new({:error => "Unable to process the pubmed metadata: #{e.message}"})
      end
    end

    alias_method_chain :parse_article, :extension
  end

end