class SearchController < ApplicationController
  include Seek::FacetedBrowsing

  class InvalidSearchException < RuntimeError; end

  api_actions :index

  def index
    @results = {}
    @external_results = []

    if Seek::Config.solr_enabled
      begin
        perform_search
      rescue InvalidSearchException => e
        flash.now[:error] = e.message
      rescue RSolr::Error::ConnectionRefused => e
        flash.now[:error] = "The search service is currently not running, and we've been notified of the problem. Please try again later"

        Seek::Errors::ExceptionForwarder.send_notification(e, env: request.env, data: { message: 'An error with search occurred, SOLR connection refused.' })
      end
    end

    if Scale.any?
      @scale_key = search_params[:scale] || 'all'
      unless @scale_key == 'all'
        @results.each do |type, results|
          klass = type.constantize
          if klass.reflect_on_association(:scales)
            @results[type] = results.joins(:scales).where(scales: { key: @scale_key })
          end
        end
      end
    end

    matches = @results.values.sum(&:count) + @external_results.count
    if matches.zero?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'.".html_safe
    else
      flash.now[:notice]="#{matches} #{matches==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content.".html_safe
    end

    view_context.ie_support_faceted_browsing? if Seek::Config.faceted_search_enabled

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

  def perform_search
    @search_query = ActionController::Base.helpers.sanitize(search_params[:q] || search_params[:search_query])
    @search = @search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query ||=""
    @search_type = search_params[:search_type] || 'all'
    type = @search_type&.downcase

    @search_query = Seek::Search::SearchTermFilter.filter @search_query

    downcase_query = @search_query.downcase

    searchable_types = Seek::Util.searchable_types

    raise InvalidSearchException.new("Query string is empty or blank") if downcase_query.blank?

    if Seek::Config.solr_enabled
      if type == "all"
        sources = searchable_types
        sources -= [Strain, Sample] if request.format.json?
      else
        type_name = type.singularize.camelize
        raise InvalidSearchException.new("#{type} is not a valid search type") unless searchable_types.map(&:to_s).include?(type_name)
        sources = [type_name.constantize]
      end

      sources.each do |source|
        @results[source.to_s] = source.with_search_query(downcase_query).authorized_for('view')
      end

      if search_params[:include_external_search] == "1"
        @external_results = Seek::ExternalSearch.instance.external_search(downcase_query, type)
      end

      @results
    end
  end

  private

  def search_params
    params.permit(:search_type, :q, :search_query, :include_external_search, :scale)
  end
end
