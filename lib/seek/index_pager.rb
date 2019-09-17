module Seek
  module IndexPager
    include Seek::FacetedBrowsing

    def index
      controller = controller_name.downcase
      model_class = controller_name.classify.constantize
      objects = eval("@#{controller}")
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

    def fetch_and_filter_assets
      detect_parent_resource
      found = fetch_all_viewable_assets
      found = apply_filters(found)
      instance_variable_set("@#{controller_name.downcase}", found)
    end

    def fetch_all_viewable_assets
      found = if @parent_resource
                @parent_resource.get_related(controller_name.classify)
              else
                controller_name.classify.constantize
              end

      @total_count = found.count
      found = found.authorized_for('view', User.current_user)
      @hidden = @total_count - found.count

      found
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
  end
end
