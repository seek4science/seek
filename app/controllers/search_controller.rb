class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @search_query = params[:search_query]
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?
    
    @results=[]
    case(type)
    when("people")
      @results = Person.multi_solr_search(@search_query, :limit=>100, :models=>[Person]).results if (SOLR_ENABLED and !@search_query.nil? and !@search_query.strip.empty?)      
    when("institutions")
      @results = Institution.multi_solr_search(@search_query, :limit=>100, :models=>[Institution]).results if (SOLR_ENABLED and !@search_query.nil? and !@search_query.strip.empty?)
    when("projects")
      @results = Project.multi_solr_search(@search_query, :limit=>100, :models=>[Project]).results if (SOLR_ENABLED and !@search_query.nil? and !@search_query.strip.empty?)
    else
      @results = Person.multi_solr_search(@search_query, :limit=>100, :models=>[Person, Project, Institution]).results if (SOLR_ENABLED and !@search_query.nil? and !@search_query.strip.empty?)      
    end
    
    
  end
  
end
