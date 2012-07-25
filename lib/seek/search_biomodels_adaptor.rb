require 'search_biomodel'

module Seek

  class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :date_published, :pubmed_id)

    def initialize
      self.authors = []
    end

    def populate pubmed_id
      query = PubmedQuery.new("seek@sysmo-db.org", Seek::Config.pubmed_api_email)
      self.pubmed_id = pubmed_id
      puts "pubmed_id = #{pubmed_id}"
      query_result_yaml = Rails.cache.fetch("pubmed_fetch_#{pubmed_id}") do
        result = query.fetch(pubmed_id)
        result.to_yaml
      end
      query_result = YAML::load(query_result_yaml)
      if (query_result.authors.size > 0)
        query_result.authors.each do |pubname|
          self.authors << pubname.name.to_s
        end
      end

      self.abstract = query_result.abstract
      self.date_published = query_result.date_published
      self.title = query_result.title
    end

  end

  class SearchBiomodelsAdaptor < AbstractSearchAdaptor

    def search query
      if !Seek::Config.pubmed_api_email.blank?
        connection = SysMODB::SearchBiomodel.instance
        connection.models(query).collect do |result|
          if !result.nil? && !result[:publication_id].blank?
            r=BiomodelsSearchResult.new
            r.populate result[:publication_id]
            r
          else
            nil
          end
        end.compact
      else
        Rails.logger.warn("Pubmed email not defined, so skipping biomodels search")
        []
      end
    end

  end

end