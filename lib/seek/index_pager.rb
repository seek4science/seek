module Seek
  module IndexPager
    include Seek::FacetedBrowsing

    def index
      respond_to do |format|
        format.html
        format.xml
        format.json do
          render json: instance_variable_get("@#{controller_name}"),
                 each_serializer: SkeletonSerializer,
                 links: json_api_links,
                 meta: {
                     base_url: Seek::Config.site_base_host,
                     api_version: ActiveModel::Serializer.config.api_version
                 }
        end
      end
    end

    def find_assets
      assign_index_variables

      assets = nil
      log_with_time("  - Fetched #{controller_name}") { assets = fetch_assets }
      log_with_time("  - Filtered") { assets = filter_assets(assets) }
      log_with_time("  - Sorted") { assets = sort_assets(assets) }
      log_with_time("  - Paged") { assets = paginate_assets(assets) }

      instance_variable_set("@#{controller_name}", assets)
    end

    def fetch_assets
      if @parent_resource
        @parent_resource.get_related(controller_name.classify)
      else
        controller_model
      end
    end

    def filter_assets(assets)
      unfiltered_assets = assets
      authorized_unfiltered_assets = relationify_collection(unfiltered_assets.authorized_for('view', User.current_user))
      filterer = Seek::Filterer.new(controller_model)
      active_filter_values = filterer.active_filter_values(@filters)
      # We need the un-filtered, but authorized, collection to work out which filters are available.
      @available_filters = filterer.available_filters(authorized_unfiltered_assets, active_filter_values)
      if active_filter_values.any?
        authorized_filtered_assets = filterer.filter(authorized_unfiltered_assets, active_filter_values)
      else
        authorized_filtered_assets = authorized_unfiltered_assets
        @total_count = unfiltered_assets.count
      end

      @visible_count = authorized_filtered_assets.count

      active_filter_values.each_key do |key|
        active = @available_filters[key].select(&:active?)
        @active_filters[key] = active if active.any?
      end

      authorized_filtered_assets
    end

    def sort_assets(assets)
      order = Seek::ListSorter.order_from_keys(*@order)

      Seek::ListSorter.index_items(assets, order)
    end

    def paginate_assets(assets)
      if @page.match?(/[0-9]+/) # Standard pagination
        assets.paginate(page: @page, per_page: params[:per_page] || Seek::Config.limit_latest)
      elsif @page == 'all' # No pagination
        assets.paginate(page: 1, per_page: 1_000_000)
      else # Alphabetical pagination
        controller_model.paginate_after_fetch(assets, page_and_sort_params)
      end
    end

    private

    def assign_index_variables
      # Parent resource
      parent_id_param = request.path_parameters.keys.detect { |k| k.to_s.end_with?('_id') }
      if parent_id_param
        parent_type = parent_id_param.to_s.chomp('_id')
        parent_class = parent_type.camelize.constantize
        if parent_class
          @parent_resource = parent_class.find(params[parent_id_param])
        end
      end

      # Page
      @page = page_and_sort_params[:page]
      @page ||= 'all' if json_api_request?
      @page ||= '1'

      # Order
      @order = if page_and_sort_params[:sort]
                 Seek::ListSorter.keys_from_json_api_sort(page_and_sort_params[:sort])
               else
                 page_and_sort_params[:order]
               end
      # Sort by `updated_at` if on the "top", and its a valid sort option for this type.
      @order ||= :updated_at_desc if @page == 'top' && Seek::ListSorter.options(controller_model.name).include?(:updated_at_desc)
      # Sort by `title` if on an alphabetical page, and its a valid sort option for this type.
      @order ||= :title_asc if @page.match?(/[?A-Z]+/) && Seek::ListSorter.options(controller_model.name).include?(:title_asc)
      @order ||= Seek::ListSorter.key_for_view(controller_model.name, :index)
      @order = Array.wrap(@order).map(&:to_sym)

      # Filters
      @filters = page_and_sort_params[:filter].to_h
      @active_filters = {}
      @available_filters = {}
    end

    # This is a silly method to turn an Array of AR objects back into an AR relation so we can do joins etc. on it.
    def relationify_collection(collection)
      if collection.is_a?(Array)
        controller_model.where(id: collection.map(&:id))
      else
        collection
      end
    end

    def json_api_links
      if @parent_resource
        base = [@parent_resource, controller_name.to_sym]
      else
        base = controller_name.to_sym
      end

      {
        self: polymorphic_path(base, page_and_sort_params)
      }
    end

    def log_with_time(message, &block)
      t = Time.now
      block.call
      Rails.logger.debug("#{message} (#{((Time.now - t) * 1000.0).round(1)}ms)")
    end
  end
end
