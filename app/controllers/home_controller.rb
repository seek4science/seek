class HomeController < ApplicationController
  

  before_filter :redirect_to_sign_up_when_no_user


  def index
    respond_to do |format|
      format.html # index.html.erb      
    end
  end

  def faq
    respond_to do |format|
      format.html 
    end
  end
  
  def feedback
    respond_to do |format|
      format.html
    end
  end

  def send_feedback
    subject=params[:subject]
    anon=params[:anon]
    details=params[:details]
    
    anon=anon=="true"

    puts "Anon = #{anon}"

    if subject.nil? or details.nil?
      flash[:error]="You must provide a Subject and details"
      render :action=>:feedback
    else
      if (Seek::Config.email_enabled)
        Mailer.deliver_feedback(current_user,subject,details,anon,base_host)
      end
      flash[:notice]="Your feedback has been delivered. Thank You."
      redirect_to root_path
    end
  end

  def redirect_to_sign_up_when_no_user
    if User.count == 0
      redirect_to :controller => 'users', :action => 'new'
    end
  end

  def recent_changes
    respond_to do |format|
      format.html
    end
  end

  def seek_intro_demo
     respond_to do |format|
      format.html
    end
  end


  def scale_search
    @scale = Scale.find_by_title(params[:scale_type])
    scalings = @scale.scalings.select { |s| !s.scalable.nil? }
    @scaled_objects = scalings.select(&:can_view?).collect { |scaling| scaling.scalable }.uniq

    resource_hash={}

    @scaled_objects.each do |res|
      resource_hash[res.class.name] = {:items => [], :hidden_count => 0} unless resource_hash[res.class.name]
      resource_hash[res.class.name][:items] << res
    end


     render :update  do |page|

      page.replace_html "scaled_items_id", :partial=>"assets/resource_listing_tabbed_by_class", :locals =>{:resource_hash=>resource_hash,
                           :narrow_view => true,
                           :authorization_already_done => true}




#
#     p "###########################"
#      page.call 'Element.replace', 'my_element', "My content to replace with."
#
#
#      page.call "Element.append","jQuery(\"#scaled_items_id\").html", :partial=>"assets/resource_listing_tabbed_by_class", :locals =>{:resource_hash=>resource_hash,
#                           :narrow_view => true,
#                           :authorization_already_done => true}
#
#      puts page
#       p "ddddddddddd"



   end

  end



  private

  RECENT_SIZE=3

 

  def classify_for_tabs result_collection
    #FIXME: this is duplicated in application_helper - but of course you can't call that from within controller
    results={}

    result_collection.each do |res|
      results[res.class.name] = [] unless results[res.class.name]
      results[res.class.name] << res
    end

    return results
  end

end
