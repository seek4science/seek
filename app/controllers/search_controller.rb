class SearchController < ApplicationController

  def index

    if Seek::Config.solr_enabled
      perform_search()
    else
      @results = []
    end

    #strip out nils, which can occur if the index is out of sync
    @results = @results.select{|r| !r.nil?}

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

    @search_query.strip!

    #if you use colon in query, solr understands that field_name:value, so if you put the colon at the end of the search query, solr will throw exception
    #remove the : if the string ends with :
    if @search_query.ends_with?':'
      flash.now[:error]="You cannot end a query with a colon, so this was removed"
      @search_query.chop!
    end

    downcase_query = @search_query.downcase
    downcase_query.gsub!(":","")
    downcase_query.gsub!(":","")

    @results=[]
    if (Seek::Config.solr_enabled and !downcase_query.blank?)
      case (type)
        when ("people")
          @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results
        when ("institutions")
          @results = Institution.multi_solr_search(downcase_query, :limit=>100, :models=>[Institution]).results
        when ("projects")
          @results = Project.multi_solr_search(downcase_query, :limit=>100, :models=>[Project]).results
        when ("sops")
          @results = Sop.multi_solr_search(downcase_query, :limit=>100, :models=>[Sop]).results
        when ("studies")
          @results = Study.multi_solr_search(downcase_query, :limit=>100, :models=>[Study]).results
        when ("models")
          @results = Model.multi_solr_search(downcase_query, :limit=>100, :models=>[Model]).results
        when ("data files")
          @results = DataFile.multi_solr_search(downcase_query, :limit=>100, :models=>[DataFile]).results
        when ("investigations")
          @results = Investigation.multi_solr_search(downcase_query, :limit=>100, :models=>[Investigation]).results
        when ("assays")
          @results = Assay.multi_solr_search(downcase_query, :limit=>100, :models=>[Assay]).results
        when ("publications")
          @results = Publication.multi_solr_search(downcase_query, :limit=>100, :models=>[Publication]).results
        when ("presentations")
          @results = Presentation.multi_solr_search(downcase_query, :limit=>100, :models=>[Presentation]).results
        when ("events")
          @results = Event.multi_solr_search(downcase_query, :limit=>100, :models=>[Event]).results
        when ("specimens")
          @results = Specimen.multi_solr_search(downcase_query, :limit=>100, :models=>[Specimen]).results
        when ("samples")
          @results = Sample.multi_solr_search(downcase_query, :limit=>100, :models=>[Sample]).results
        else
          sources = [Person, Project, Institution, Sop, Model, Study, DataFile, Assay, Investigation, Publication, Presentation, Sample, Specimen, Event]

          @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>sources).results
      end
    end
  end

  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

end
