module Seek
  module IndexPager
    include Seek::FacetedBrowsing

    def index
      controller = controller_name.downcase
      unless view_context.index_with_facets?(controller) && params[:user_enable_facet] == 'true'
        model_class = controller_name.classify.constantize
        objects = eval("@#{controller}")
        @hidden = 0
        params[:page] ||= Seek::Config.default_page(controller)

        objects = model_class.paginate_after_fetch(objects, page: params[:page],
                                                            latest_limit: Seek::Config.limit_latest
                                                  ) unless objects.respond_to?('page_totals')
        instance_variable_set("@#{controller}", objects)
      end

      respond_to do |format|
        format.html
        format.xml
      end
    end

    def find_assets
      fetch_and_filter_assets
    end

    def fetch_and_filter_assets
      found = apply_filters(fetch_all_viewable_assets)
      instance_variable_set("@#{controller_name.downcase}", found)
    end

    def fetch_all_viewable_assets
      model_class = controller_name.classify.constantize
      if model_class.respond_to? :all_authorized_for
        found = model_class.all_authorized_for 'view', User.current_user
      else
        found = model_class.respond_to?(:default_order) ? model_class.default_order : model_class.all
      end
      found
    end
  end
end
