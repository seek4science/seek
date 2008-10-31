class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @query = params[:query]
    @results=[]
    @results = Profile.multi_solr_search(@query, :limit=>100, :models=>[Profile, Project, Institution]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
    
  end
  
end
