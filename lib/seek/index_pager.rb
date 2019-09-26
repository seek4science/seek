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
                 meta: {:base_url =>   Seek::Config.site_base_host,
                        :api_version => ActiveModel::Serializer.config.api_version
                 }
          end
      end
    end

    def find_assets
      detect_parent_resource
      Rails.logger.debug("--- Fetching #{controller_name}")
      assets = fetch_assets
      Rails.logger.debug("--- Filtering")
      assets = filter_assets(assets)
      Rails.logger.debug("--- Sorting")
      assets = sort_assets(assets)
      Rails.logger.debug("--- Paging")
      assets = paginate_assets(assets)
      Rails.logger.debug("--- Done!")
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
      @filters = page_and_sort_params[:filter].to_h
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

      @active_filters = {}
      active_filter_values.each_key do |key|
        active = @available_filters[key].select(&:active?)
        @active_filters[key] = active if active.any?
      end

      authorized_filtered_assets
    end

    def sort_assets(assets)
      order_keys = page_and_sort_params[:order]
      order_keys ||= :updated_at_desc if page_and_sort_params[:page] == 'top' && Seek::ListSorter.options(controller_model.name).include?(:updated_at_desc)
      order_keys ||= Seek::ListSorter.key_for_view(controller_model.name, :index)
      order_keys = Array.wrap(order_keys).map(&:to_sym)
      order = Seek::ListSorter.order_from_keys(*order_keys)

      Seek::ListSorter.index_items(assets, order)
    end

    def paginate_assets(assets)
      page = page_and_sort_params[:page]
      if page.blank? || page.match?(/[0-9]+/) # Standard pagination
        assets.paginate(page: page, per_page: params[:per_page] || Seek::Config.limit_latest)
      elsif page == 'all' # No pagination
        assets.paginate(page: 1, per_page: 1_000_000)
      else # Alphabetical pagination
        controller_model.paginate_after_fetch(assets, page_and_sort_params)
      end
    end

    def detect_parent_resource
      parent_id_param = request.path_parameters.keys.detect { |k| k.to_s.end_with?('_id') }
      if parent_id_param
        parent_type = parent_id_param.to_s.chomp('_id')
        parent_class = parent_type.camelize.constantize
        if parent_class
          @parent_resource = parent_class.find(params[parent_id_param])
        end
      end
    end

    private

    # This is a silly method to turn an Array of AR objects back into an AR relation so we can do joins etc. on it.
    def relationify_collection(collection)
      if collection.is_a?(Array)
        controller_model.where(id: collection.map(&:id))
      else
        collection
      end
    end
  end
end
