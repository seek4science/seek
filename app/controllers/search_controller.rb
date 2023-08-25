class SearchController < ApplicationController
  class InvalidSearchException < RuntimeError; end

  api_actions :index

  def index
    @results = {}
    @external_results = []

    if Seek::Config.solr_enabled
      begin
        determine_query
        sources = determine_sources
        if jump_straight_to_filtered_view?(sources)
          redirect_to polymorphic_path(sources[0], 'filter[query]': @search_query)
        else
          perform_search(sources)
          respond_with_search_results
        end
      rescue InvalidSearchException => e
        flash.now[:error] = e.message
      rescue RSolr::Error::ConnectionRefused => e
        flash.now[:error] =
          "The search service is currently not running, and we've been notified of the problem. Please try again later"

        Seek::Errors::ExceptionForwarder.send_notification(e, env: request.env,
                                                              data: { message: 'An error with search occurred, SOLR connection refused.' })
      end
    end
  end

  def perform_search(sources)
    downcase_query = @search_query.downcase

    sources.each do |source|
      @results[source.to_s] = source.with_search_query(downcase_query).authorized_for('view')
    end

    if search_params[:include_external_search] == '1'
      @external_results = Seek::ExternalSearch.instance.external_search(downcase_query, @search_type&.downcase)
    end

    @results
  end

  private

  def jump_straight_to_filtered_view?(sources)
    !request.format.json? && sources.count == 1 && search_params[:include_external_search] != '1'
  end

  def determine_query
    @search_query = ActionController::Base.helpers.sanitize(search_params[:q] || search_params[:search_query])
    @search = @search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query ||= ''
    @search_query = Seek::Search::SearchTermFilter.filter @search_query
    raise InvalidSearchException, 'Query string is empty or blank' if @search_query.blank?
  end

  def determine_sources
    @search_type = search_params[:search_type] || 'all'
    type = @search_type&.downcase
    searchable_types = Seek::Util.searchable_types

    if type == 'all'
      sources = searchable_types
      sources -= [Strain, Sample] if request.format.json?
    else
      type_name = type.singularize.camelize
      unless searchable_types.map(&:to_s).include?(type_name)
        raise InvalidSearchException, "#{type} is not a valid search type"
      end

      sources = [safe_class_lookup(type_name)]
    end
    sources
  end

  def respond_with_search_results
    matches = @results.values.sum(&:count) + @external_results.count
    if matches.zero?
      flash.now[:notice] = "No matches found for '<b>#{h(@search_query)}</b>'.".html_safe
    else
      flash.now[:notice] =
        "#{matches} #{matches == 1 ? 'item' : 'items'} matched '<b>#{h(@search_query)}</b>' within their title or content.".html_safe
    end

    respond_to do |format|
      format.html
      format.json do
        render json: @results.values.inject(&:+),
               each_serializer: SkeletonSerializer,
               links: { self: search_path(search_params) },
               meta: {
                 base_url: Seek::Config.site_base_host,
                 api_version: ActiveModel::Serializer.config.api_version
               }
      end
    end
  end

  def search_params
    params.permit(:search_type, :q, :search_query, :include_external_search)
  end
end
