module Seek
  module IndexPager
    include Seek::FacetedBrowsing

    def index
      controller = controller_name.downcase
      model_class = controller_name.classify.constantize
      objects = eval("@#{controller}")
      @visible_count = objects.count
      objects = model_class.paginate_after_fetch(objects, page_and_sort_params) unless objects.respond_to?('page_totals')
      instance_variable_set("@#{controller}", objects)

      respond_to do |format|
        format.html
        format.xml
        format.json do
          render json: objects,
                 each_serializer: SkeletonSerializer,
                 meta: {:base_url =>   Seek::Config.site_base_host,
                        :api_version => ActiveModel::Serializer.config.api_version
                 }
          end
      end
    end

    def find_assets
      fetch_and_filter_assets
    end

    def filter_params
      # placed this in a separate method so that other controllers could override it if necessary
      return {} unless params.key?(:filter)
      permitted = controller_name.classify.constantize.applicable_filters.flat_map { |p| [p, { p => [] }] }
      params.require(:filter).permit(*permitted).to_h
    end

    def fetch_and_filter_assets
      detect_parent_resource
      unfiltered_assets = fetch_all_assets
      authorized_unfiltered_assets = relationify_collection(unfiltered_assets.authorized_for('view', User.current_user))
      @filters = filter_params
      filterer = Seek::Filter.new(controller_name.classify.constantize)
      @active_filters = filterer.active_filters(@filters)
      @available_filters = filterer.available_filters(authorized_unfiltered_assets, @active_filters)
      if @active_filters.any?
        authorized_filtered_assets = filterer.filter(authorized_unfiltered_assets, @active_filters)
      else
        authorized_filtered_assets = authorized_unfiltered_assets
        @total_count = unfiltered_assets.count
      end
      # We need the un-filtered, but authorized, collection to work out which filters are available.
      instance_variable_set("@#{controller_name.downcase}", authorized_filtered_assets)
    end

    def fetch_all_assets
      if @parent_resource
        @parent_resource.get_related(controller_name.classify)
      else
        controller_name.classify.constantize
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
        if collection.empty?
          Sop.where('1=0') # Sop chosen arbitrarily. Will always return an empty relation.
        else
          collection.first.class.where(id: collection.map(&:id))
        end
      else
        collection
      end
    end
  end
end
