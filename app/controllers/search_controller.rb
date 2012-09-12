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

    @results_scaled = Scale.all.collect {|scale| [scale.title, @results.select {|item| !item.respond_to?(:scale_ids) or item.scale_ids.include? scale.id}]}
    @results_scaled << ['all', @results]
    @results_scaled = Hash[*@results_scaled.flatten(1)]
    logger.info @results_scaled.inspect
    if params[:scale]
      # when user does not login, params[:scale] is nil
      @results = @results_scaled[params[:scale]]
      @scale_title = params[:scale]
    else
       @results = @results_scaled['all']
       @scale_title = 'all'
    end


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

    @search_query = @search_query.gsub("*","")
    @search_query = @search_query.gsub("?","")

    @search_query.strip!

    #if you use colon in query, solr understands that field_name:value, so if you put the colon at the end of the search query, solr will throw exception
    #remove the : if the string ends with :
    if @search_query.ends_with?':'
      flash.now[:error]="You cannot end a query with a colon, so this was removed"
      @search_query.chop!
    end

    downcase_query = @search_query.downcase
    downcase_query.gsub!(":","")

    @results=[]
    if (Seek::Config.solr_enabled and !downcase_query.blank?)
      if type == "all"
          sources = [Person, Project, Institution, Sop, Model, Study, DataFile, Assay, Investigation, Publication, Presentation, Event, Sample, Specimen]
          sources.delete(Specimen) if !Seek::Config.is_virtualliver
          sources.each do |source|
            search_result = source.search do |query|
              query.keywords downcase_query
            end.results
            search_result = search_result.sort_by(&:published_date).reverse if source == Publication
            @results |= search_result
          end
      else
           object = type=='data_files' ? DataFile : type.singularize.capitalize.constantize
           search_result = object.search do |query|
             query.keywords downcase_query
           end.results
           search_result = search_result.sort_by(&:published_date).reverse if object == Publication
           @results = search_result
      end
    end
  end

  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

end
