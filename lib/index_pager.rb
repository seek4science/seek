module IndexPager    

  def index
    controller = self.controller_name.downcase    
    model_name=controller.classify
    model_class=eval(model_name)
    objects = eval("@"+controller)
    objects.size
    @hidden=0
    params[:page] ||= model_class.default_page

    objects=model_class.paginate_after_fetch(objects, :page=>params[:page]) unless objects.respond_to?("page_totals")
    eval("@"+controller+"= objects")

    respond_to do |format|
      format.html
      format.xml
    end

  end

  def find_assets
    controller = self.controller_name.downcase
    model_class=controller.classify.constantize
    found = model_class.all_authorized_for "view",User.current_user
    found = apply_filters(found)
    
    eval("@" + controller + " = found")
  end
  
end