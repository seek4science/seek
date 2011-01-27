module IndexPager    

  def index
    controller = self.controller_name.downcase    
    model_name=controller.classify
    model_class=eval(model_name)
    objects = eval("@"+controller)
    objects.size
    @hidden=0
    params[:page] ||= "all"
    
    if Authorization::ASSET_TYPES.include?(model_class.name)
      authorized=[]
      auth_pages={}      
      objects.each do |object|
        if params[:page]=="all"
          authorized << object if Authorization.is_authorized?("show",nil,object,current_user)        
        #In the next 2 cases we need to authorize at most one item for the non displayed pages,so we keep a hash and skip over any once we've collected
        #one for that page. Then paginate_after_fetch will then contain a page_total of 1 for the other pages, so that it is enabled in the view. 
        #I don't want to put this logic in the GroupedPagination library, as I wish to keep it authorization agostic and record correct page_totals in normal use.
        elsif params[:page]=="latest" && (authorized.size<model_class.latest_limit || auth_pages[object.first_letter].nil?)          
          if Authorization.is_authorized?("show",nil,object,current_user)
            authorized << object
            auth_pages[object.first_letter]=true
          end          
        elsif model_class.pages.include?(object.first_letter) && (object.first_letter == params[:page] || auth_pages[object.first_letter].nil?)                    
          if Authorization.is_authorized?("show",nil,object,current_user)
            authorized << object
            auth_pages[object.first_letter]=true
          end                             
        end
      end      
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
    params[:page]||="all"
    controller = self.controller_name.downcase
    model_name=controller.classify
    model_class=eval(model_name)    
    order_field = params[:page]=="latest" ? "created_at DESC" : "title"
    found = model_class.find(:all, :order => order_field)
    found = apply_filters(found)        
    
    eval("@" + controller + " = found")
  end
  
end