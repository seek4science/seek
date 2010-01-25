class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @search_query = params[:search_query]
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    downcase_query = @search_query.downcase
    
    @results=[]
    case(type)
    when("people")
      @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when("institutions")
      @results = Institution.multi_solr_search(downcase_query, :limit=>100, :models=>[Institution]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when("projects")
      @results = Project.multi_solr_search(downcase_query, :limit=>100, :models=>[Project]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when ("sops")
      @results = Sop.multi_solr_search(downcase_query, :limit=>100, :models=>[Sop]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when ("studies")
      @results = Study.multi_solr_search(downcase_query, :limit=>100, :models=>[Study]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when ("models")
      @results = Model.multi_solr_search(downcase_query, :limit=>100, :models=>[Model]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when ("data files")
      @results = DataFile.multi_solr_search(downcase_query, :limit=>100, :models=>[DataFile]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
   when ("investigations")
      @results = Investigation.multi_solr_search(downcase_query, :limit=>100, :models=>[Investigation]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
   when ("assays")
      @results = Assay.multi_solr_search(downcase_query, :limit=>100, :models=>[Assay]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    else
      @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person, Project, Institution,Sop,Model,Study,DataFile,Assay,Investigation]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    end

    @results = select_authorised @results
    
    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    else
      flash.now[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content."
    end
    
  end
  
  
  
  

  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
  
end
