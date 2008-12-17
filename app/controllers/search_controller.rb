class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @query = params[:query]
    type = params[:type]
    type=type.downcase unless type.nil?
    
    @results=[]
    case(type)
    when("people")
      @results = Person.multi_solr_search(@query, :limit=>100, :models=>[Person]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
      @results = @results.select{|r| (!r.instance_of?(Person) || !r.is_dummy?)}
    when("institutions")
      @results = Institution.multi_solr_search(@query, :limit=>100, :models=>[Institution]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
    when("projects")
      @results = Project.multi_solr_search(@query, :limit=>100, :models=>[Project]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
    else
      @results = Person.multi_solr_search(@query, :limit=>100, :models=>[Person, Project, Institution]).results if (SOLR_ENABLED and !@query.nil? and !@query.strip.empty?)
      @results = @results.select{|r| (!r.instance_of?(Person) || !r.is_dummy?)}
    end
    
    
  end
  
end
