class SearchController < ApplicationController

  def index

    if Seek::Config.solr_enabled
      perform_search()
    else
      @results = []
    end


    @results = select_authorised @results    
    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    else
      flash.now[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content."
    end
    
  end

  def perform_search
    @search_query = params[:search_query]
    @search=@search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    if @search_query.start_with?("*") || @search_query.start_with?("?")
      flash.now[:error]="You cannot start a query with a wildcard, so this was removed. You CAN however include wildcards at the end or within the query."
      @search_query=@search_query[1..-1] while @search_query.start_with?("*") || @search_query.start_with?("?")
    end

    downcase_query = @search_query.downcase

    @results=[]
    case (type)
      when ("people")
        @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("institutions")
        @results = Institution.multi_solr_search(downcase_query, :limit=>100, :models=>[Institution]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("projects")
        @results = Project.multi_solr_search(downcase_query, :limit=>100, :models=>[Project]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("sops")
        @results = Sop.multi_solr_search(downcase_query, :limit=>100, :models=>[Sop]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
        search_in_experimental_condition
      when ("studies")
        @results = Study.multi_solr_search(downcase_query, :limit=>100, :models=>[Study]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("models")
        @results = Model.multi_solr_search(downcase_query, :limit=>100, :models=>[Model]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("data files")
        @results = DataFile.multi_solr_search(downcase_query, :limit=>100, :models=>[DataFile]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
        search_in_factors_studied
      when ("investigations")
        @results = Investigation.multi_solr_search(downcase_query, :limit=>100, :models=>[Investigation]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("assays")
        @results = Assay.multi_solr_search(downcase_query, :limit=>100, :models=>[Assay]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      when ("publications")
        @results = Publication.multi_solr_search(downcase_query, :limit=>100, :models=>[Publication]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      else
        @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person, Project, Institution, Sop, Model, Study, DataFile, Assay, Investigation, Publication]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
        search_in_factors_studied
        search_in_experimental_condition
    end
  end

  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

  def search_in_factors_studied
    downcase_query = @search_query.downcase
    factors_studies = StudiedFactor.multi_solr_search(downcase_query, :limit=>100, :models=>[StudiedFactor]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
    factors_studies.each do |fs|
      @results.push(fs.data_file) if !@results.include? fs.data_file
    end
  end

  def search_in_experimental_condition
    downcase_query = @search_query.downcase
    experimental_conditions = ExperimentalCondition.multi_solr_search(downcase_query, :limit=>100, :models=>[ExperimentalCondition]).results if (Seek::Config.solr_enabled and !downcase_query.nil? and !downcase_query.strip.empty?)
      experimental_conditions.each do |ec|
        @results.push(ec.sop) if !@results.include? ec.sop
    end
  end
end
