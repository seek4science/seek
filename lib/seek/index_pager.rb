module Seek
  module IndexPager
    extend ActiveSupport::Concern

    included do
      after_action :index_fair_signposting, only: [:index], if: -> { controller_model.schema_org_supported? }
    end

    def index
      respond_to do |format|
        format.html
        format.json do
          render json: instance_variable_get("@#{controller_name}"),
                 each_serializer: SkeletonSerializer,
                 links: json_api_links,
                 meta: {
                     base_url: Seek::Config.site_base_host,
                     api_version: ActiveModel::Serializer.config.api_version
                 }
        end
        if controller_model.schema_org_supported?
          format.jsonld do
            if params[:dump]
              dump = controller_model.public_schema_ld_dump
              if dump.exists?
                send_file(dump.file, type: :jsonld)
              else
                head :not_found
              end
            else
              resource = determine_resource_for_schema_ld
              render json: Seek::BioSchema::Serializer.new(resource).json_representation, adapter: :attributes
            end
          end
        end
      end
    end

    def find_assets
      assign_index_variables

      assets = nil
      log_with_time("  - Fetched #{controller_name}") { assets = fetch_assets }
      @total_count = assets.count
      log_with_time("  - Authorized") { assets = authorize_assets(assets) }
      log_with_time("  - Relation-ified") { assets = relationify_collection(assets) } if assets.is_a?(Array)
      assets = filter_assets(assets) if Seek::Config.filtering_enabled
      @visible_count = assets.count
      log_with_time("  - Sorted") { assets = sort_assets(assets) }
      log_with_time("  - Paged") { assets = paginate_assets(assets) }

      instance_variable_set("@#{controller_name}", assets)
    end

    # returns either the related assets if there is a parent resource, or the controller model if the result would be all of them.
    def fetch_assets
      if @parent_resource
        @parent_resource.get_related(controller_name.classify)
      else
        if controller_model == SampleType && Seek::Config.project_single_page_advanced_enabled
          return SampleType.without_template
        end

        controller_model
      end
    end

    def authorize_assets(assets)
      assets.authorized_for('view', User.current_user)
    end

    def filter_assets(assets)
      filterer = Seek::Filterer.new(controller_model)
      active_filter_values = filterer.active_filter_values(@filters)
      # We need the un-filtered, but authorized, collection to work out which filters are available.
      @available_filters = nil
      log_with_time("  - Calculated available filters") { @available_filters = filterer.available_filters(assets, active_filter_values) }
      log_with_time("  - Filtered") { assets = filterer.filter(assets, active_filter_values) if active_filter_values.any? }

      active_filter_values.each_key do |key|
        active = @available_filters[key].select(&:active?)
        @active_filters[key] = active if active.any?
      end

      assets
    end

    def sort_assets(assets)
      Seek::ListSorter.sort_by_order(assets, Seek::ListSorter.order_from_keys(*@order))
    end

    def paginate_assets(assets)
      if @page.match?(/^[0-9]+$/) # Standard pagination
        assets.paginate(page: @page,
                        per_page: @per_page)
      elsif @page == 'all' # No pagination
        assets.paginate(page: 1, per_page: 1_000_000)
      elsif @page.match?(/^[A-Z]$/) || @page=='?' || @page=='top' # Alphabetical pagination
        controller_model.paginate_after_fetch(assets, page_and_sort_params)
      else #default to 1 if invalid page
        @page=1
        assets.paginate(page: @page,
                        per_page: @per_page)
      end
    end

    private

    # Takes into account current view, and returns the appropriate max results per page
    def get_results_per_page

      condensed_view_count = is_condensed_view? ? Seek::Config.results_per_page_default_condensed : false

      # Priorities for the results per page value
      # per_page param > controller specific config > specific view default > general default
      params[:per_page]&.to_i ||
          Seek::Config.results_per_page_for(controller_name) ||
          condensed_view_count ||
          Seek::Config.results_per_page_default
    end

    def assign_index_variables
      # Parent resource
      get_parent_resource

      # Page
      @page = page_and_sort_params[:page]
      @page ||= 'all' if json_api_request?
      @page ||= '1'
      @per_page = get_results_per_page

      # Order
      @order = if page_and_sort_params[:sort]
                 Seek::ListSorter.keys_from_json_api_sort(controller_model.name, page_and_sort_params[:sort])
               else
                 Seek::ListSorter.keys_from_params(controller_model.name, page_and_sort_params[:order])
               end
      if @order.empty?
        @order = nil
        # Sort by `updated_at` if on the "top", and its a valid sort option for this type.
        @order = :updated_at_desc if @page == 'top' && Seek::ListSorter.options(controller_model.name).include?(:updated_at_desc)
        # Sort by `title` if on an alphabetical page, and its a valid sort option for this type.
        @order = :title_asc if @page.match?(/[?A-Z]+/) && Seek::ListSorter.options(controller_model.name).include?(:title_asc)
        @order ||= :relevance if page_and_sort_params.dig(:filter, :query).present? && Seek::Config.solr_enabled
        @order ||= Seek::Config.sorting_for(controller_name)&.to_sym
        @order ||= Seek::ListSorter.key_for_view(controller_model.name, :index)
      end
      @order = Array.wrap(@order).map(&:to_sym)

      # Filters
      @filters = page_and_sort_params[:filter].to_h
      @active_filters = {}
      @available_filters = {}
    end

    def json_api_links
      idx = controller_name.to_sym
      if @parent_resource
        idx = :items if @parent_resource.is_a?(Collection) # Collection items use ".../items" as their path
        base = [@parent_resource, idx]
      else
        base = idx
      end

      { self: polymorphic_path(base, page_and_sort_params) }
    end

    def log_with_time(message, &block)
      t = Time.now
      block.call
      Rails.logger.debug("#{message} (#{((Time.now - t) * 1000.0).round(1)}ms)")
    end

    def index_fair_signposting
      @fair_signposting_links = [[polymorphic_url(controller_model), { rel: :describedby, type: :jsonld }]]
    end
  end
end
