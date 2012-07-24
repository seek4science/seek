require 'search_biomodel'

module Seek

  class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :date_published, :pubmed_id)

    def initialize
      @authors = []
    end

    def populate pubmed_id
      query = PubmedQuery.new("seek", Seek::Config.pubmed_api_email)
      @pubmed_id = pubmed_id
      query_result = Rails.cache.read(@pubmed_id)
      if query_result.nil?
        query_result = query.fetch(@pubmed_id)
        Rails.cache.write(@pubmed_id, query_result)
      end

      if (query_result.authors.size > 0)

        query_result.authors.each do |pubname|
          @authors << pubname.name.to_s
        end
      end
      @abstract = query_result.abstract
      @date_published = query_result.date_published
      @title = query_result.title
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