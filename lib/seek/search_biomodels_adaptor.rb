require 'search_biomodel'

module Seek
  class SearchBiomodelsAdaptor < SearchAdaptor

    def search query
      connection = SysMODB::SearchBiomodel.instance
      connection.models(query)
    end
  end

end



#@ext_results["biomodels"] = []
#@connection = SysMODB::SearchBiomodel.instance
#@ext_results["biomodels"] = @connection.models(@search_query)
#@ext_results["biomodels"].each_with_index do |res, i|
#  sleep 0.4
#  query = PubmedQuery.new("seek", Seek::Config.pubmed_api_email)
#  if !res.nil? && !res[:publication_id].nil? && res[:publication_id] != ""
#    query_result = Rails.cache.read(res[:publication_id])
#    if query_result.nil?
#      query_result = query.fetch(res[:publication_id])
#      Rails.cache.write(res[:publication_id], query_result)
#    else
#      #flash.now[:notice] = "#{Rails.cache.read(:publication_id).abstract}"
#    end
#
#    if (query_result.authors.size > 0)
#      @ext_results["biomodels"][i][:authors] = Array.new
#      query_result.authors.each_with_index do |pubname, j|
#        @ext_results["biomodels"][i][:authors][j] = pubname.name.to_s
#      end
#    end
#    @ext_results["biomodels"][i][:abstract] = query_result.abstract
#    @ext_results["biomodels"][i][:date_published] = query_result.date_published
#    @ext_results["biomodels"][i][:title] = query_result.title
#  else
#    @ext_results["biomodels"].delete_at(i)
#  end
#end