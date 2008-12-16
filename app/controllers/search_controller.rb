class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @query = params[:query]
    @results=[]
    @results = Person.multi_solr_search(@query, :limit=>100, :models=>[Person, Project, Institution]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
    @results = @results.select{|r| (!r.instance_of?(Person) || !r.is_dummy?)}
    
  end
  
end
