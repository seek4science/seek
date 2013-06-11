class AdminsController < ApplicationController
  include CommonSweepers

  RESTART_MSG = "You settings have been updated. If you enabled search you need to restart your server.
                 If deployed in conjunction with Passenger Phusion you can use the button at the bottom of this page,
                 otherwise you need to restart manually."
  
  before_filter :login_required
  before_filter :is_user_admin_auth



  def show
    respond_to do |format|
      format.html
    end
  end

  def update_admins
    admin_ids = params[:admins] || []
    current_admins = Person.admins
    admins = admin_ids.collect{|id| Person.find(id)}
    current_admins.each{|ca| ca.is_admin = false}
    admins.each{|a| a.is_admin = true}
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

  def registration_form
    respond_to do |format|
      format.html
    end
  end
  
  def tags
    @tags=TextValue.all_tags.sort_by{|t| t.text}
  end

  def update_features_enabled
    Seek::Config.public_seek_enabled= string_to_boolean(params[:public_seek_enabled] || true)
    Seek::Config.events_enabled= string_to_boolean params[:events_enabled]
    Seek::Config.jerm_enabled= string_to_boolean params[:jerm_enabled]
    Seek::Config.email_enabled= string_to_boolean params[:email_enabled]
    Seek::Config.pdf_conversion_enabled= string_to_boolean params[:pdf_conversion_enabled]

    Seek::Config.set_smtp_settings 'address', params[:address]
    Seek::Config.set_smtp_settings 'domain', params[:domain]
    Seek::Config.set_smtp_settings 'authentication', params[:authentication]
    Seek::Config.set_smtp_settings 'user_name', params[:user_name]
    Seek::Config.set_smtp_settings 'password', params[:password]
    Seek::Config.set_smtp_settings 'enable_starttls_auto',params[:enable_starttls_auto]=="1"

    Seek::Config.solr_enabled= string_to_boolean params[:solr_enabled]
    Seek::Config.jws_enabled= string_to_boolean params[:jws_enabled]
    Seek::Config.jws_online_root= params[:jws_online_root]

    Seek::Config.exception_notification_recipients = params[:exception_notification_recipients]
    Seek::Config.exception_notification_enabled = string_to_boolean params[:exception_notification_enabled]

    Seek::Config.hide_details_enabled= string_to_boolean params[:hide_details_enabled]
    Seek::Config.activation_required_enabled= string_to_boolean params[:activation_required_enabled]

    Seek::Config.google_analytics_tracker_id= params[:google_analytics_tracker_id]
    Seek::Config.google_analytics_enabled= string_to_boolean params[:google_analytics_enabled]

    Seek::Config.piwik_analytics_enabled= string_to_boolean params[:piwik_analytics_enabled]
    Seek::Config.piwik_analytics_id_site= params[:piwik_analytics_id_site]
    Seek::Config.piwik_analytics_url= params[:piwik_analytics_url]

    Seek::Config.set_smtp_settings 'port', params[:port] if only_integer params[:port], 'port'
    update_redirect_to (only_integer params[:port], "port"),'features_enabled'
  end

  def update_home_settings
    Seek::Config.project_news_enabled= string_to_boolean params[:project_news_enabled]
    Seek::Config.project_news_feed_urls= params[:project_news_feed_urls]
    Seek::Config.project_news_number_of_entries= params[:project_news_number_of_entries] if only_integer params[:tag_threshold], "number of project news"

    Seek::Config.community_news_enabled= string_to_boolean params[:community_news_enabled]
    Seek::Config.community_news_feed_urls= params[:community_news_feed_urls]
    Seek::Config.community_news_number_of_entries= params[:community_news_number_of_entries] if only_integer params[:tag_threshold], "number of community news"

    Seek::Config.home_description = params[:home_description]
    begin
      Seek::FeedReader.clear_cache
    rescue e
      logger.error "Error whilst attempting to clear feed cache #{e.message}"
    end
    update_redirect_to true,'home_settings'
  end

  def rebrand
      respond_to do |format|
      format.html
    end
  end

  def update_rebrand
    Seek::Config.project_name= params[:project_name]
    Seek::Config.project_type= params[:project_type]
    Seek::Config.project_link= params[:project_link]
    Seek::Config.project_title= params[:project_title]
    Seek::Config.project_long_name= params[:project_long_name]

    Seek::Config.dm_project_name= params[:dm_project_name]
    Seek::Config.dm_project_title= params[:dm_project_title]
    Seek::Config.dm_project_link= params[:dm_project_link]

    Seek::Config.application_name= params[:application_name]
    Seek::Config.application_title= params[:application_title]

    Seek::Config.header_image_enabled= string_to_boolean params[:header_image_enabled]
    Seek::Config.header_image= params[:header_image]
    Seek::Config.header_image_link= params[:header_image_link]
    Seek::Config.header_image_title= params[:header_image_title]

    Seek::Config.copyright_addendum_enabled= string_to_boolean params[:copyright_addendum_enabled]
    Seek::Config.copyright_addendum_content= params[:copyright_addendum_content]

    Seek::Config.noreply_sender= params[:noreply_sender]

    update_redirect_to true,'rebrand'
  end

  def update_pagination
   update_flag = true
   Seek::Config.set_default_page "people",params[:people]
   Seek::Config.set_default_page "projects", params[:projects]
   Seek::Config.set_default_page "institutions", params[:institutions]
   Seek::Config.set_default_page "investigations", params[:investigations]
   Seek::Config.set_default_page "studies", params[:studies]
   Seek::Config.set_default_page "assays", params[:assays]
   Seek::Config.set_default_page "data_files", params[:data_files]
   Seek::Config.set_default_page "models", params[:models]
   Seek::Config.set_default_page "sops", params[:sops]
   Seek::Config.set_default_page "publications", params[:publications]
   Seek::Config.set_default_page "presentations", params[:presentations]
   Seek::Config.set_default_page "events", params[:events]
   Seek::Config.limit_latest= params[:limit_latest] if only_positive_integer params[:limit_latest], "latest limit"
   update_redirect_to (only_positive_integer params[:limit_latest], 'latest limit'),'pagination'
  end

  def update_others
    update_flag = true
    if Seek::Config.tag_threshold.to_s != params[:tag_threshold] || Seek::Config.max_visible_tags.to_s!=params[:max_visible_tags]
      expire_annotation_fragments
    end
    Seek::Config.site_base_host = params[:site_base_host] unless params[:site_base_host].nil?
    #check valid email
    Seek::Config.pubmed_api_email = params[:pubmed_api_email] if params[:pubmed_api_email] == '' || (check_valid_email params[:pubmed_api_email], "pubmed api email")
    Seek::Config.crossref_api_email = params[:crossref_api_email] if params[:crossref_api_email] == '' || (check_valid_email params[:crossref_api_email], "crossref api email")

    Seek::Config.bioportal_api_key = params[:bioportal_api_key]
    Seek::Config.tag_threshold = params[:tag_threshold] if only_integer params[:tag_threshold], "tag threshold"
    Seek::Config.max_visible_tags = params[:max_visible_tags] if only_positive_integer params[:max_visible_tags], "maximum visible tags"
    Seek::Config.sabiork_ws_base_url = params[:sabiork_ws_base_url] unless params[:sabiork_ws_base_url].nil?
    update_flag = (params[:pubmed_api_email] == '' ||(check_valid_email params[:pubmed_api_email], "pubmed api email")) && (params[:crossref_api_email] == '' || (check_valid_email params[:crossref_api_email], "crossref api email")) && (only_integer params[:tag_threshold], "tag threshold") && (only_positive_integer params[:max_visible_tags], "maximum visible tags")
    update_redirect_to update_flag,'others'
  end

  def update_biosamples_renaming
    update_flag = true
    Seek::Config.sample_parent_term = params[:sample_parent_term] unless params[:sample_parent_term].blank?
    Seek::Config.specimen_creators = params[:specimen_creators] unless params[:specimen_creators].blank?
    Seek::Config.specimen_culture_starting_date = params[:specimen_culture_starting_date] unless params[:specimen_culture_starting_date].blank?
    Seek::Config.sample_age = params[:sample_age] unless params[:sample_age].blank?
    update_redirect_to update_flag,'biosamples_renaming'
  end
  def restart_server
    system ("touch #{Rails.root}/tmp/restart.txt")
    flash[:notice] = 'The server was restarted'
    redirect_to :action=>:show
  end

  def edit_tag
    if request.post?
      @tag=TextValue.find(params[:id])
      replacement_tags = []

      params[:tags_autocompleter_selected_ids].each do |selected_id|
          replacement_tags << TextValue.find(selected_id)
      end unless params[:tags_autocompleter_selected_ids].nil?
      params[:tags_autocompleter_unrecognized_items].select{|t| !t.blank?}.each do |item|
          tag = TextValue.find_by_text(item)
          tag = TextValue.create :text=>item if tag.nil?
          replacement_tags << tag
      end unless params[:tags_autocompleter_unrecognized_items].nil?
      
      @tag.annotations.each do |a|
        annotatable = a.annotatable
        source = a.source
        attribute_name = a.attribute.name
        a.destroy unless replacement_tags.include?(@tag)
        replacement_tags.each do |tag|
          if annotatable.annotations_with_attribute_and_by_source(attribute_name, source).select{|a| a.value == tag}.blank?
            new_annotation = Annotation.new :attribute_name=>attribute_name, :value=>tag, :annotatable => annotatable, :source => source
            new_annotation.save!
          end
        end
      end

      @tag=TextValue.find(params[:id])

      @tag.destroy if @tag.annotations.blank?

      expire_annotation_fragments

      redirect_to :action=>:tags
    else
      @tag=TextValue.find(params[:id])
      @all_tags_as_json=TextValue.all.collect{|t| {'id'=>t.id, 'name'=>t.text}}.to_json
      respond_to do |format|
        format.html
      end
    end

  end

  def delete_tag
    tag=TextValue.find(params[:id])
    if request.post?
      tag.annotations.each do |a|
        a.delete
      end
      tag.delete
      flash.now[:notice]="Tag #{tag.text} deleted"

    else
      flash.now[:error]="Must be a post"
    end

    expire_annotation_fragments

    redirect_to :action=>:tags
  end
  
  def get_stats
    collection = []
    type = nil
    title = nil
    @page=params[:id]
    case @page
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
        pal_role=ProjectRole.pal_role
        collection[:pal_mismatch] = Person.all.select {|p| p.is_pal? != p.project_roles.include?(pal_role)}
        collection[:duplicates] = Person.duplicates
        collection[:no_person] = User.without_profile
      when "not_activated"
        title = "Users requiring activation"
        collection = User.not_activated
        type = "users"
      when "projectless"
        title = "Users not in a #{Seek::Config.project_name} project"
        collection = Person.without_group.registered
        type = "users"
      when "contents"
        type = "content_stats"
      when "activity"
        type = "activity_stats"
      when "search"
        type = "search_stats"
      when "job_queue"
        type = "job_queue"
      when "auth_consistency"
        type = "auth_consistency"
      when "none"
        type = "none"
    end
    respond_to do |format|
      case type
        when "invalid_users"
          format.html { render :partial => "admins/invalid_user_stats_list", :locals => { :collection => collection} }
        when "users"
          format.html { render :partial => "admins/user_stats_list", :locals => { :title => title, :collection => collection} }
        when "content_stats"
          format.html { render :partial => "admins/content_stats", :locals => {:stats => Seek::ContentStats.generate} }
        when "activity_stats"
          format.html { render :partial => "admins/activity_stats", :locals => {:stats => Seek::ActivityStats.new} }
        when "search_stats"
          format.html { render :partial => "admins/search_stats", :locals => {:stats => Seek::SearchStats.new} }
        when "job_queue"
          format.html { render :partial => "admins/job_queue" }
        when "auth_consistency"
          format.html { render :partial => "admins/auth_consistency" }
        when "none"
          format.html { render :text=>"" }
      end
    end
  end

  def test_email_configuration
    smtp_hash_old = ActionMailer::Base.smtp_settings
    smtp_hash_new = {:address => params[:address], :enable_starttls_auto => params[:enable_starttls_auto]=="1", :domain => params[:domain], :authentication => params[:authentication], :user_name => (params[:user_name].blank? ? nil : params[:user_name]), :password => (params[:password].blank? ? nil : params[:password])}
    smtp_hash_new[:port] = params[:port] if only_integer params[:port], 'port'
    ActionMailer::Base.smtp_settings = smtp_hash_new
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
        begin
          Mailer.test_email(params[:testing_email]).deliver
          render :update do |page|
            page.replace_html "ajax_loader_position", "<div id='ajax_loader_position'></div>"
            page.alert("test email is sent successfully to #{params[:testing_email]}")
          end
        rescue Exception => e
          render :update do |page|
            page.replace_html "ajax_loader_position", "<div id='ajax_loader_position'></div>"
            page.alert("Fail to send test email, #{e.message}")
          end
        ensure
          ActionMailer::Base.smtp_settings = smtp_hash_old
          ActionMailer::Base.raise_delivery_errors = raise_delivery_errors_setting
        end
  end

  private

  def created_at_data_for_model model
    x={}
    start="1 Nov 2008"

    x[Date.parse(start).jd]=0
    x[Date.today.jd]=0

    model.order(:created_at).each do |i|
      date=i.created_at.to_date
      day=date.jd
      x[day] ||= 0
      x[day]+=1
    end
    sorted_keys=x.keys.sort
    (sorted_keys.first..sorted_keys.last).collect{|i| x[i].nil? ? 0 : x[i]  }
  end

  def check_valid_email email_address, field
    if email_address =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
      return true
    else
      flash[:error] = "Please input the correct #{field}"
      return false
    end
  end

  def only_integer input, field
     begin
       Integer(input)
       return true
     rescue
       flash[:error] = "Please enter the correct #{field}"
       return false
     end
  end

  def only_positive_integer input, field
     begin
       if Integer(input) > 0
         return true
       else
         flash[:error] = "Please enter the correct #{field}"
         return false
       end
     rescue
       flash[:error] = "Please enter the correct #{field}"
       return false
     end
  end

  def string_to_boolean string
      if string == '1'
        return true
      else
        return false
      end
  end

  def update_redirect_to flag, action
     if flag
       flash[:notice] = RESTART_MSG
       expire_header_and_footer
       redirect_to :action=>:show
     else
       redirect_to :action=> action.to_s
     end
  end
end
