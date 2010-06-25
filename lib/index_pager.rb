module IndexPager
  
  def index
    controller = self.controller_name.downcase    
    model_name=controller.classify
    model_class=eval(model_name)
    objects = eval("@"+controller)
    
    params[:page] ||= "latest"
    
    objects=Authorization.authorize_collection("show",objects,current_user) if (model_class.respond_to?("acts_as_resource"))
    objects=model_class.paginate_after_fetch(objects, :page=>params[:page]) unless objects.respond_to?("page_totals")
    respond_to do |format|
      format.html
      format.xml
    end    
  end
  
end