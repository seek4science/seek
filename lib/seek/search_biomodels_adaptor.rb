require 'search_biomodel'

module Seek



  class SearchBiomodelsAdaptor < AbstractSearchAdaptor

    def search query
      if !Seek::Config.pubmed_api_email.blank?
        connection = SysMODB::SearchBiomodel.instance
        #FIXME: needs redoing, as we need more than the pubmed id - also need the model_id and last_modification_date
        pubmed_ids = Rails.cache.fetch("biomodels_search_#{query}",:expires_in=>1.hour) do
          biomodels_result = connection.models(query)
          biomodels_result.collect do |r|
            if r.nil? || r[:publication_id].blank?
              nil
            else
              r[:publication_id]
            end
          end.compact
        end

        pubmed_ids.collect do |id|
            r=BiomodelsSearchResult.new
            r.populate id
            r
        end
      else
        Rails.logger.warn("Pubmed email not defined, so skipping biomodels search")
        []
      end
    end

  end

  class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :date_published, :pubmed_id, :tab, :model_id, :last_modification_date)

    include Seek::ExternalSearchResult

    def initialize
      self.authors = []
      self.tab="Biomodels"
      self.model_id="1"
    end

    def populate pubmed_id
      query = PubmedQuery.new("seek@sysmo-db.org", Seek::Config.pubmed_api_email)
      self.pubmed_id = pubmed_id
      query_result_yaml = Rails.cache.fetch("pubmed_fetch_#{pubmed_id}",:expires_in=>1.week) do
        result = query.fetch(pubmed_id)
        result.to_yaml
      end
      puts query_result_yaml
      query_result = YAML::load(query_result_yaml)
      if (query_result.authors.size > 0)
        query_result.authors.each do |pubname|
          self.authors << pubname.name.to_s
        end
      end

      self.abstract = query_result.abstract
      self.date_published = query_result.date_published
      self.last_modification_date = Time.now
      self.title = query_result.title
    end

  end

end