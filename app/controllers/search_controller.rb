class SearchController < ApplicationController

  before_filter :set_default_search_params

  include Seek::ExternalSearch
  include Seek::FacetedBrowsing

  def index

    if Seek::Config.solr_enabled
      perform_search (request.format.json?)
    else
      @results = []
    end

    #strip out nils, which can occur if the index is out of sync
    @results.compact!
    #select only items, that can be viewed by the current_user
    @results.select!(&:can_view?)

    @results_scaled = Scale.all.collect {|scale| [scale.key, @results.select {|item| !item.respond_to?(:scale_ids) or item.scale_ids.include? scale.id}]}
    @results_scaled << ['all', @results]
    @results_scaled = Hash[*@results_scaled.flatten(1)]
    logger.info @results_scaled.inspect
    if params[:scale]
      # when user does not login, params[:scale] is nil
      @results = @results_scaled[params[:scale]]
      @scale_key = params[:scale]
    else
       @results = @results_scaled['all']
       @scale_key = 'all'
    end


    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'.".html_safe
    else
      flash.now[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content.".html_safe
    end

    @include_external_search = params[:include_external_search]=="1"

    view_context.ie_support_faceted_browsing? if Seek::Config.faceted_search_enabled

    respond_to do |format|
      format.html
      format.json {render json: @results,
                          each_serializer: SkeletonSerializer,
                          meta: {:base_url =>   Seek::Config.site_base_host,
                                 :api_version => ActiveModel::Serializer.config.api_version
                          }}
    end
    
  end

  def perform_search (is_json = false)
    @search_query = params[:q] || params[:search_query]
    @search=@search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    @search_query = Seek::Search::SearchTermFilter.filter @search_query

    downcase_query = @search_query.downcase

    @results=[]

    searchable_types = Seek::Util.searchable_types

    if (Seek::Config.solr_enabled and !downcase_query.blank?)
      if type == "all"
          sources = searchable_types
          if is_json
            sources -= [Strain, Sample]
          end
          sources.each do |source|
            search = source.search do |query|
              query.keywords(downcase_query)
              query.paginate(:page => 1, :per_page => source.count ) if source.count > 30  # By default, Sunspot requests the first 30 results from Solr
            end #.results
            @search_hits = search.hits
            search_result = search.results
            @results |= search_result
          end
      else
           search_type = type.singularize.camelize.constantize
           raise "#{type} is not a valid search type" unless searchable_types.include?(search_type)
           search = search_type.search do |query|
             query.keywords(downcase_query)
             query.paginate(:page => 1, :per_page => search_type.count ) if search_type.count > 30 # By default, Sunspot requests the first 30 results from Solr
           end #.results
           @search_hits = search.hits
           search_result = search.results
           @results = search_result
      end

      if (params[:include_external_search]=="1")
        external_results = external_search downcase_query,type
        @results |= external_results
      end

      @results = apply_filters(@results)
    end

  end

  private

  def set_default_search_params
    params[:include_external_search] ||= 0
    params[:search_type] = 'all' if params[:search_type].blank?
  end

  def include_external_search?
    Seek::Config.external_search_enabled && params[:include_external_search]
  end

end
