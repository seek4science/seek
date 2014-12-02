module IndexPager    
  include Seek::FacetedBrowsing

  def index
    controller = self.controller_name.downcase
    unless index_with_facets?
      model_class=self.controller_name.classify.constantize
      objects = eval("@#{controller}")
      @hidden=0
      params[:page] ||= Seek::Config.default_page(controller)

      objects=model_class.paginate_after_fetch(objects, :page=>params[:page],
                                                        :latest_limit => Seek::Config.limit_latest
                                              ) unless objects.respond_to?("page_totals")
      instance_variable_set("@#{controller}",objects)
    end

    respond_to do |format|
      format.html
      format.xml
    end

  end

  def index_with_facets?
    Seek::Config.faceted_browsing_enabled && Seek::Config.facet_enable_for_pages[self.controller_name.downcase] && ie_support_faceted_browsing?
  end

  def find_assets
    begin
      fetch_and_filter_assets
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html do
            render :template => "errors/error_404", :layout=>"errors",:status => :not_found
        end
      end
    end
  end

  def fetch_and_filter_assets
    found = apply_filters(fetch_all_viewable_assets)
    instance_variable_set("@#{self.controller_name.downcase}",found)
  end

  def fetch_all_viewable_assets
    model_class=self.controller_name.classify.constantize
    if model_class.respond_to? :all_authorized_for
      found = model_class.all_authorized_for "view", User.current_user
    else
      found = model_class.respond_to?(:default_order) ? model_class.default_order : model_class.all
    end
    return found
  end

end