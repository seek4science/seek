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
        citation_volume = article.find_first('.//Volume') ? article.find_first('.//Volume').content : ""
        citation_issue = article.find_first('.//Issue') ? "(" + article.find_first('.//Issue').content + ")" : ""
        citation_med_line_pgn = article.find_first('.//MedlinePgn').content
        citation_med_line_pgn=": " + citation_med_line_pgn unless citation_med_line_pgn == ""
        pubmed_record.citation = citation_iso_abbreviation + " " + citation_volume + citation_issue + citation_med_line_pgn

        return pubmed_record
      rescue Exception => e
        return PubmedRecord.new({:error => "Unable to process the pubmed metadata: #{e.message}"})
      end
    end

    alias_method_chain :parse_article, :extension
  end

end