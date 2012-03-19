module IndexPager    

  def index
    controller = self.controller_name.downcase    
    model_name=controller.classify
    model_class=eval(model_name)
    objects = eval("@"+controller)
    objects.size
    @hidden=0
    params[:page] ||= model_class.default_page
    
    if !objects.empty? && Authorization::authorization_supported?(objects.first)
      authorized=[]
      auth_pages={}
      if params[:page]=="all"
        authorized |= authorized_objects objects, 'view'
      else
        objects.each do |object|
          #In the next 2 cases we need to authorize at most one item for the non displayed pages,so we keep a hash and skip over any once we've collected
          #one for that page. Then paginate_after_fetch will then contain a page_total of 1 for the other pages, so that it is enabled in the view.
          #I don't want to put this logic in the GroupedPagination library, as I wish to keep it authorization agostic and record correct page_totals in normal use.
          if params[:page]=="latest" && (authorized.size<model_class.latest_limit || auth_pages[object.first_letter].nil?)
            if object.can_view?
              authorized << object
              auth_pages[object.first_letter]=true
            end
          elsif model_class.pages.include?(object.first_letter) && (object.first_letter == params[:page] || auth_pages[object.first_letter].nil?)
            if object.can_view?
              authorized << object
              auth_pages[object.first_letter]=true
            end
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

  def authorized_objects objects, action
    person = User.current_user.try(:person)
    key = person.nil? ? ['anonymous_user'] : person.generate_person_key
    key << action
    key << objects.first.class.name
    authorized_objects =  Rails.cache.fetch(key){
      objects.select{|o| o.send "can_#{action}?"}
    }
    authorized_objects
  end
  
  def find_assets    
    controller = self.controller_name.downcase
    model_class=controller.classify.constantize
    found = model_class.find(:all)
    found = apply_filters(found)
    
    eval("@" + controller + " = found")
  end
  
end