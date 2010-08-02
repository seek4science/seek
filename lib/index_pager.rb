module IndexPager    
  
  def index
    controller = self.controller_name.downcase    
    model_name=controller.classify
    model_class=eval(model_name)
    objects = eval("@"+controller)
    objects.size
    @hidden=0
    params[:page] ||= "latest"
    
    if Authorization::ASSET_TYPES.include?(model_class.name) 
      authorized=Authorization.authorize_collection("show",objects,current_user)
      @hidden=objects.size - authorized.size
      objects=authorized
    end
    objects=model_class.paginate_after_fetch(objects, :page=>params[:page]) unless objects.respond_to?("page_totals")
    eval("@"+controller+"= objects")
    
    respond_to do |format|
      format.html
      format.xml
    end
    
  end
  
  def find_assets
    controller = self.controller_name.downcase
    model_name=controller.classify
    model_class=eval(model_name)
    found = model_class.find(:all, 
      :order => "title")
    found = apply_filters(found)    
      
    eval("@" + controller + " = found")
  end
  
end