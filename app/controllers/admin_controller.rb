class AdminController < ApplicationController
  include CommonSweepers
  
  before_filter :login_required
  before_filter :is_user_admin_auth

  def show
    respond_to do |format|
      format.html
    end
  end

  def update_admins
    admin_ids = params[:admins] || []
    current_admins = Person.all.select{|p| p.is_admin?}
    admins = admin_ids.collect{|id| Person.find(id)}
    current_admins.each{|ca| ca.is_admin=false}
    admins.each{|a| a.is_admin=true}
    (admins | current_admins).each do |admin|
      class << admin
        def record_timestamps
          false
        end
      end
      admin.save
    end
    redirect_to :action=>:show
  end
  
  def tags
    @tags=ActsAsTaggableOn::Tag.find(:all,:order=>:name)
  end

  def update_features_enabled
    if params[:events_enabled] == "1"
      Seek::ApplicationConfiguration.events_enabled=true
    else
      Seek::ApplicationConfiguration.events_enabled=false
    end

    if params[:jerm_enabled] == "1"
      Seek::ApplicationConfiguration.jerm_enabled=true
    else
      Seek::ApplicationConfiguration.jerm_enabled=false
    end

    if params[:email_enabled] == "1"
      Seek::ApplicationConfiguration.email_enabled=true
    else
      Seek::ApplicationConfiguration.email_enabled=false
    end
    Seek::ApplicationConfiguration.set_smtp_settings 'email', params[:email]
    Seek::ApplicationConfiguration.set_smtp_settings 'port', params[:port]
    Seek::ApplicationConfiguration.set_smtp_settings 'domain', params[:domain]
    Seek::ApplicationConfiguration.set_smtp_settings 'authentication', params[:authentication]
    Seek::ApplicationConfiguration.set_smtp_settings 'user_name', params[:user_name]
    Seek::ApplicationConfiguration.set_smtp_settings 'password', params[:password]

    Seek::ApplicationConfiguration.noreply_sender=params[:noreply_sender]

    if params[:solr_enabled] == "1"
      Seek::ApplicationConfiguration.solr_enabled= true
    else
      Seek::ApplicationConfiguration.solr_enabled= false
    end

    if params[:jws_enabled] == "1"
      Seek::ApplicationConfiguration.jws_enabled= true
    else
      Seek::ApplicationConfiguration.jws_enabled= false
    end

    Seek::ApplicationConfiguration.jws_online_root= params[:jws_online_root]

    if params[:exception_notification_enabled] == "1"
      Seek::ApplicationConfiguration.exception_notification_enabled= true
    else
      Seek::ApplicationConfiguration.exception_notification_enabled= false
    end

    if params[:hide_details_enabled] == "1"
      Seek::ApplicationConfiguration.hide_details_enabled= true
    else
      Seek::ApplicationConfiguration.hide_details_enabled= false
    end

    if params[:activity_log_enabled] == "1"
      Seek::ApplicationConfiguration.activity_log_enabled= true
    else
      Seek::ApplicationConfiguration.activity_log_enabled= false
    end

    if params[:activation_required_enabled] == "1"
      Seek::ApplicationConfiguration.activation_required_enabled= true
    else
      Seek::ApplicationConfiguration.activation_required_enabled= false
    end

    if params[:google_analytics_enabled] == "1"
      Seek::ApplicationConfiguration.google_analytics_enabled= true
    else
      Seek::ApplicationConfiguration.google_analytics_enabled= false
    end
    Seek::ApplicationConfiguration.google_analytics_tracker_id= params[:google_analytics_tracker_id]
    finalize_config_changes
  end

  def rebrand
      respond_to do |format|
      format.html
    end
  end

  def update_rebrand
    Seek::ApplicationConfiguration.project_name= params[:project_name]
    Seek::ApplicationConfiguration.project_type= params[:project_type]
    Seek::ApplicationConfiguration.project_link= params[:project_link]
    Seek::ApplicationConfiguration.project_title= params[:project_title]
    Seek::ApplicationConfiguration.project_long_name= params[:project_long_name]

    Seek::ApplicationConfiguration.dm_project_name= params[:dm_project_name]
    Seek::ApplicationConfiguration.dm_project_title= params[:dm_project_title]
    Seek::ApplicationConfiguration.dm_project_link= params[:dm_project_link]

    Seek::ApplicationConfiguration.application_name= params[:application_name]
    Seek::ApplicationConfiguration.application_title= params[:application_title]

    if params[:header_image_enabled] == "1"
     Seek::ApplicationConfiguration.header_image_enabled= true
    else
     Seek::ApplicationConfiguration.header_image_enabled= false
    end
    Seek::ApplicationConfiguration.header_image= params[:header_image]
    Seek::ApplicationConfiguration.header_image_link= params[:header_image_link]
    Seek::ApplicationConfiguration.header_image_title= params[:header_image_title]
    if params[:copyright_addendum_enabled] == "1"
      Seek::ApplicationConfiguration.copyright_addendum_enabled= true
    else
      Seek::ApplicationConfiguration.copyright_addendum_enabled= false
    end
    Seek::ApplicationConfiguration.copyright_addendum_content= params[:copyright_addendum_content]
    finalize_config_changes
  end

  def update_pagination
   Seek::ApplicationConfiguration.set_default_page "people",params[:people]
   Seek::ApplicationConfiguration.set_default_page "projects", params[:projects]
   Seek::ApplicationConfiguration.set_default_page "institutions", params[:institutions]
   Seek::ApplicationConfiguration.set_default_page "investigations", params[:investigations]
   Seek::ApplicationConfiguration.set_default_page "studies", params[:studies]
   Seek::ApplicationConfiguration.set_default_page "assays", params[:assays]
   Seek::ApplicationConfiguration.set_default_page "data_files", params[:data_files]
   Seek::ApplicationConfiguration.set_default_page "models", params[:models]
   Seek::ApplicationConfiguration.set_default_page "sops", params[:sops]
   Seek::ApplicationConfiguration.set_default_page "publications", params[:publications]
   Seek::ApplicationConfiguration.set_default_page "events", params[:events]
   Seek::ApplicationConfiguration.limit_latest= params[:limit_latest]
   finalize_config_changes
  end

  def update_others
    if params[:type_managers_enabled] == "1"
     Seek::ApplicationConfiguration.type_managers_enabled= true
    else
     Seek::ApplicationConfiguration.type_managers_enabled= false
    end
    Seek::ApplicationConfiguration.type_managers= params[:type_managers]
    Seek::ApplicationConfiguration.pubmed_api_email= params[:pubmed_api_email]
    Seek::ApplicationConfiguration.crossref_api_email= params[:crossref_api_email]
    Seek::ApplicationConfiguration.site_base_host= params[:site_base_host]
    Seek::ApplicationConfiguration.open_id_authentication_store= params[:open_id_authentication_store]
    Seek::ApplicationConfiguration.tag_threshold= params[:tag_threshold]
    Seek::ApplicationConfiguration.max_visible_tags= params[:max_visible_tags]

  end

  def finalize_config_changes
    flash[:notice] = 'To apply the change, please click the "Restart server" button if your webserver is Apache, or manually restart the server'
    #expires all fragment caching
    expire_all_fragments
    redirect_to :action=>:show
  end

  def restart_server
    system ("touch #{RAILS_ROOT}/tmp/restart.txt")
    flash[:notice] = 'The server was restarted'
    redirect_to :action=>:show
  end

  def edit_tag
    if request.post?
      @tag=ActsAsTaggableOn::Tag.find(params[:id])
      @tag.taggings.select{|t| !t.taggable.nil?}.each do |tagging|
        context_sym=tagging.context.to_sym
        taggable=tagging.taggable
        current_tags=taggable.tag_list_on(context_sym).select{|tag| tag!=@tag.name}
        new_tag_list=current_tags.join(", ")

        replacement_tags=", "
        params[:tags_autocompleter_selected_ids].each do |selected_id|
          tag=ActsAsTaggableOn::Tag.find(selected_id)
          replacement_tags << tag.name << ","
        end unless params[:tags_autocompleter_selected_ids].nil?
        params[:tags_autocompleter_unrecognized_items].each do |item|
          replacement_tags << item << ","
        end unless params[:tags_autocompleter_unrecognized_items].nil?

        new_tag_list=new_tag_list << replacement_tags

        method_sym="#{tagging.context.singularize}_list=".to_sym

        taggable.send method_sym, new_tag_list

        taggable.save

      end

      @tag=ActsAsTaggableOn::Tag.find(params[:id])
      
      @tag.destroy if @tag.taggings.select{|t| !t.taggable.nil?}.empty?

      #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
      expire_fragment("sidebar_tag_cloud")

      redirect_to :action=>:tags
    else
      @tag=ActsAsTaggableOn::Tag.find(params[:id])
      @all_tags_as_json=ActsAsTaggableOn::Tag.find(:all).collect{|t| {'id'=>t.id, 'name'=>t.name}}.to_json
      respond_to do |format|
        format.html
      end
    end

  end

  def delete_tag
    tag=ActsAsTaggableOn::Tag.find(params[:id])
    if request.post?
      tag.delete
      flash.now[:notice]="Tag #{tag.name} deleted"

    else
      flash.now[:error]="Must be a post"
    end

    #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
    expire_fragment("sidebar_tag_cloud")

    redirect_to :action=>:tags
  end
  
  def get_stats
    collection = []
    type = nil
    title = nil
    case params[:id]
      when "pals"
        title = "PALs"
        collection = Person.pals
        type = "users"
      when "admins"
        title = "Administrators"
        collection = Person.admins
        type = "users"
      when "invalid"
        collection = {}
        type = "invalid_users"
        pal_role=Role.find(:first,:conditions=>{:name=>"#{Seek::ApplicationConfiguration.dm_project_name} Pal"})
        collection[:pal_mismatch] = Person.find(:all).select {|p| p.is_pal? != p.roles.include?(pal_role)}
        collection[:duplicates] = Person.duplicates
        collection[:no_person] = User.without_profile
      when "not_activated"
        title = "Users requiring activation"
        collection = User.not_activated
        type = "users"
      when "projectless"
        title = "Users not in a #{Seek::ApplicationConfiguration.project_name} project"
        collection = Person.without_group.registered
        type = "users"
      when "contents"
        type = "content_stats"
      when "activity"
        type = "activity_stats"
      when "search"
        type = "search_stats"
      else
    end
    respond_to do |format|
      case type
        when "invalid_users"
          format.html { render :partial => "admin/invalid_user_stats_list", :locals => { :collection => collection} }          
        when "users"
          format.html { render :partial => "admin/user_stats_list", :locals => { :title => title, :collection => collection} }
        when "content_stats"
          format.html { render :partial => "admin/content_stats", :locals => {:stats => Seek::ContentStats.generate} }
        when "activity_stats"
          format.html { render :partial => "admin/activity_stats", :locals => {:stats => Seek::ActivityStats.new} }
        when "search_stats"
          format.html { render :partial => "admin/search_stats", :locals => {:stats => Seek::SearchStats.new} }
      end
    end
  end

  private

  def created_at_data_for_model model
    x={}
    start="1 Nov 2008"

    x[Date.parse(start).jd]=0
    x[Date.today.jd]=0

    model.find(:all, :order=>:created_at).each do |i|
      date=i.created_at.to_date
      day=date.jd
      x[day] ||= 0
      x[day]+=1
    end
    sorted_keys=x.keys.sort
    (sorted_keys.first..sorted_keys.last).collect{|i| x[i].nil? ? 0 : x[i]  }
  end

end
