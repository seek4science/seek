class SearchController < ApplicationController

  include Seek::ExternalSearch

  def index

    if Seek::Config.solr_enabled
      perform_search
    else
      @results = []
    end

    #strip out nils, which can occur if the index is out of sync
    @results = @results.select{|r| !r.nil?}

    @results = select_authorised @results
    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'.".html_safe
    else
      flash.now[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content.".html_safe
    end

    @include_external_search = params[:include_external_search]=="1"

    respond_to do |format|
      format.html
    end
    
  end

  def perform_search
    @search_query = params[:search_query]
    @search=@search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    @search_query = Seek::Search::SearchTermFilter.filter @search_query

    downcase_query = @search_query.downcase

    @results=[]

    if (Seek::Config.solr_enabled and !downcase_query.blank?)
      if type == "all"
          sources = Seek::Util.searchable_types
          sources.delete(Specimen) if !Seek::Config.is_virtualliver
          sources.each do |source|
            search_result = source.search do |query|
              query.keywords(downcase_query)
            end.results
            search_result = search_result.sort_by(&:published_date).reverse if source == Publication && Seek::Config.is_virtualliver
            @results |= search_result
          end
      else
           object = type.singularize.camelize.constantize
           search_result = object.search do |query|
             query.keywords(downcase_query)
           end.results
           search_result = search_result.sort_by(&:published_date).reverse if object == Publication
           @results = search_result
      end

      if (params[:include_external_search]=="1")
        external_results = external_search downcase_query,type
        @results |= external_results
      end
    end

  end

  private

  def include_external_search?
    Seek::Config.external_search_enabled && params[:include_external_search]
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

end
