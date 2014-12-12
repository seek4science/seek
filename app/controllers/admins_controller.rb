require 'delayed/command'

class AdminsController < ApplicationController
  include CommonSweepers

  RESTART_MSG = "Your settings have been updated. If you changed some settings e.g. search, you need to restart some processes.
                 Please see the buttons and explanations below."

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
    admins = admin_ids.map { |id| Person.find(id) }
    current_admins.each { |ca| ca.is_admin = false }
    admins.each { |admin| admin.is_admin = true }
    (admins | current_admins).each do |admin|
      admin.save!
    end
    redirect_to action: :show
  end

  def registration_form
    respond_to do |format|
      format.html
    end
  end

  def tags
    @tags = TextValue.all_tags.sort_by { |tag| tag.text }
  end

  def update_features_enabled
    Seek::Config.public_seek_enabled = string_to_boolean(params[:public_seek_enabled] || true)
    Seek::Config.events_enabled = string_to_boolean params[:events_enabled]
    Seek::Config.jerm_enabled = string_to_boolean params[:jerm_enabled]
    Seek::Config.email_enabled = string_to_boolean params[:email_enabled]
    Seek::Config.pdf_conversion_enabled = string_to_boolean params[:pdf_conversion_enabled]
    Seek::Config.delete_asset_version_enabled = string_to_boolean params[:delete_asset_version_enabled]
    Seek::Config.forum_enabled = string_to_boolean params[:forum_enabled]

    Seek::Config.set_smtp_settings 'address', params[:address]
    Seek::Config.set_smtp_settings 'domain', params[:domain]
    Seek::Config.set_smtp_settings 'authentication', params[:authentication]
    Seek::Config.set_smtp_settings 'user_name', params[:user_name]
    Seek::Config.set_smtp_settings 'password', params[:password]
    Seek::Config.set_smtp_settings 'enable_starttls_auto', params[:enable_starttls_auto] == '1'

    Seek::Config.support_email_address= params[:support_email_address]

    Seek::Config.solr_enabled= string_to_boolean params[:solr_enabled]
    Seek::Config.jws_enabled= string_to_boolean params[:jws_enabled]
    Seek::Config.jws_online_root= params[:jws_online_root]

    Seek::Config.exception_notification_recipients = params[:exception_notification_recipients]
    Seek::Config.exception_notification_enabled = string_to_boolean params[:exception_notification_enabled]

    Seek::Config.hide_details_enabled = string_to_boolean params[:hide_details_enabled]
    Seek::Config.activation_required_enabled = string_to_boolean params[:activation_required_enabled]

    Seek::Config.google_analytics_tracker_id = params[:google_analytics_tracker_id]
    Seek::Config.google_analytics_enabled = string_to_boolean params[:google_analytics_enabled]

    Seek::Config.piwik_analytics_enabled = string_to_boolean params[:piwik_analytics_enabled]
    Seek::Config.piwik_analytics_id_site = params[:piwik_analytics_id_site]
    Seek::Config.piwik_analytics_url = params[:piwik_analytics_url]

    Seek::Config.doi_minting_enabled = string_to_boolean params[:doi_minting_enabled]
    Seek::Config.datacite_username = params[:datacite_username]
    Seek::Config.datacite_password_encrypt params[:datacite_password]
    Seek::Config.datacite_url = params[:datacite_url]
    Seek::Config.doi_prefix = params[:doi_prefix]
    Seek::Config.doi_suffix = params[:doi_suffix]

    time_lock_doi_for = params[:time_lock_doi_for]
    time_lock_is_integer = only_integer time_lock_doi_for, 'time lock doi for'
    Seek::Config.time_lock_doi_for = time_lock_doi_for.to_i if time_lock_is_integer

    port = params[:port]
    port_is_integer = only_integer(port, 'port')
    Seek::Config.set_smtp_settings('port', port) if port_is_integer

    Seek::Util.clear_cached

    validation_flag = time_lock_is_integer && port_is_integer
    update_redirect_to validation_flag, 'features_enabled'
  end

  def update_home_settings
    Seek::Config.project_news_enabled = string_to_boolean params[:project_news_enabled]
    Seek::Config.project_news_feed_urls = params[:project_news_feed_urls]

    project_entries = params[:project_news_number_of_entries]
    is_project_entries_integer = only_integer project_entries, "#{t('project')} news items"
    Seek::Config.project_news_number_of_entries = project_entries if is_project_entries_integer

    Seek::Config.community_news_enabled = string_to_boolean params[:community_news_enabled]
    Seek::Config.community_news_feed_urls = params[:community_news_feed_urls]

    community_entries = params[:community_news_number_of_entries]
    is_community_entries_integer = only_integer community_entries, 'community news items'
    Seek::Config.community_news_number_of_entries = community_entries if is_community_entries_integer

    Seek::Config.home_description = params[:home_description]
    begin
      Seek::FeedReader.clear_cache
    rescue => e
      logger.error "Error whilst attempting to clear feed cache #{e.message}"
    end

    validation_flag = is_project_entries_integer && is_community_entries_integer
    update_redirect_to validation_flag, 'home_settings'
  end

  def rebrand
    respond_to do |format|
    format.html
  end
  end

  def update_rebrand
    Seek::Config.project_name = params[:project_name]
    Seek::Config.project_type = params[:project_type]
    Seek::Config.project_link = params[:project_link]
    Seek::Config.project_title = params[:project_title]
    Seek::Config.project_long_name = params[:project_long_name]

    Seek::Config.dm_project_name = params[:dm_project_name]
    Seek::Config.dm_project_title = params[:dm_project_title]
    Seek::Config.dm_project_link = params[:dm_project_link]

    Seek::Config.application_name = params[:application_name]
    Seek::Config.application_title = params[:application_title]

    Seek::Config.header_image_enabled = string_to_boolean params[:header_image_enabled]
    Seek::Config.header_image = params[:header_image]
    Seek::Config.header_image_link = params[:header_image_link]
    Seek::Config.header_image_title = params[:header_image_title]

    Seek::Config.copyright_addendum_enabled = string_to_boolean params[:copyright_addendum_enabled]
    Seek::Config.copyright_addendum_content = params[:copyright_addendum_content]

    Seek::Config.noreply_sender = params[:noreply_sender]

    update_redirect_to true, 'rebrand'
  end

  def update_pagination
    update_flag = true
    Seek::Config.set_default_page 'people', params[:people]
    Seek::Config.set_default_page 'projects', params[:projects]
    Seek::Config.set_default_page 'institutions', params[:institutions]
    Seek::Config.set_default_page 'investigations', params[:investigations]
    Seek::Config.set_default_page 'studies', params[:studies]
    Seek::Config.set_default_page 'assays', params[:assays]
    Seek::Config.set_default_page 'data_files', params[:data_files]
    Seek::Config.set_default_page 'models', params[:models]
    Seek::Config.set_default_page 'sops', params[:sops]
    Seek::Config.set_default_page 'publications', params[:publications]
    Seek::Config.set_default_page 'presentations', params[:presentations]
    Seek::Config.set_default_page 'events', params[:events]
    Seek::Config.limit_latest = params[:limit_latest] if only_positive_integer params[:limit_latest], 'latest limit'
    update_redirect_to (only_positive_integer params[:limit_latest], 'latest limit'), 'pagination'
  end

  def update_others
    update_flag = true
    if Seek::Config.tag_threshold.to_s != params[:tag_threshold] || Seek::Config.max_visible_tags.to_s != params[:max_visible_tags]
      expire_annotation_fragments
    end
    Seek::Config.site_base_host = params[:site_base_host] unless params[:site_base_host].nil?
    # check valid email
    pubmed_email = params[:pubmed_api_email]
    pubmed_email_valid = check_valid_email(pubmed_email, 'pubmed api email')
    crossref_email = params[:crossref_api_email]
    crossref_email_valid = check_valid_email(crossref_email, 'crossref api email')
    Seek::Config.pubmed_api_email = pubmed_email if pubmed_email == '' || pubmed_email_valid
    Seek::Config.crossref_api_email = crossref_email if crossref_email == '' || crossref_email_valid

    max_visible_tags = params[:max_visible_tags]
    tag_threshold = params[:tag_threshold]

    Seek::Config.bioportal_api_key = params[:bioportal_api_key]
    Seek::Config.tag_threshold = tag_threshold if only_integer tag_threshold, 'tag threshold'
    Seek::Config.max_visible_tags = max_visible_tags if only_positive_integer max_visible_tags, 'maximum visible tags'
    Seek::Config.sabiork_ws_base_url = params[:sabiork_ws_base_url] unless params[:sabiork_ws_base_url].nil?
    Seek::Config.recaptcha_enabled = string_to_boolean params[:recaptcha_enabled]
    Seek::Config.recaptcha_private_key = params[:recaptcha_private_key]
    Seek::Config.recaptcha_public_key = params[:recaptcha_public_key]
    update_flag = (pubmed_email == '' || pubmed_email_valid) && (crossref_email == '' || (crossref_email_valid)) && (only_integer tag_threshold, 'tag threshold') && (only_positive_integer max_visible_tags, 'maximum visible tags')
    update_redirect_to update_flag, 'others'
  end

  def restart_server
    command = "touch #{Rails.root}/tmp/restart.txt"
    error = execute_command(command)
    redirect_with_status(error, 'server')
  end

  def restart_delayed_job
    error = nil
    if Rails.env != 'test'
      begin
        Seek::Workers.restart
        wait_for_delayed_job_to_start
      rescue => e
        error = e.message
        if Seek::Config.exception_notification_enabled
          ExceptionNotifier.notify_exception(e, data: { message: 'Problem restarting delayed job' })
        end
      end
    end

    redirect_with_status(error, 'background tasks')
  end

  # give it up to 5 seconds to start up, otherwise the page reloads too quickly and says it is not running
  def wait_for_delayed_job_to_start
    sleep(0.5)
    pid = Daemons::PidFile.new("#{Rails.root}/tmp/pids", 'delayed_job.0')
    count = 0
    while !pid.running? && (count < 10)
      sleep(0.5)
      count += 1
    end
  end

  def edit_tag
    @tag = TextValue.find(params[:id])
    if request.post?
      replacement_tags = []

      params[:tags_autocompleter_selected_ids].each do |selected_id|
        replacement_tags << TextValue.find(selected_id)
      end unless params[:tags_autocompleter_selected_ids].nil?
      params[:tags_autocompleter_unrecognized_items].select { |t| !t.blank? }.each do |item|
        tag = TextValue.find_by_text(item)
        tag = TextValue.create text: item if tag.nil?
        replacement_tags << tag
      end unless params[:tags_autocompleter_unrecognized_items].nil?

      @tag.annotations.each do |a|
        annotatable = a.annotatable
        source = a.source
        attribute_name = a.attribute.name
        a.destroy unless replacement_tags.include?(@tag)
        replacement_tags.each do |tag|
          if annotatable.annotations_with_attribute_and_by_source(attribute_name, source).select { |a| a.value == tag }.blank?
            new_annotation = Annotation.new attribute_name: attribute_name, value: tag, annotatable: annotatable, source: source
            new_annotation.save!
          end
        end
      end

      @tag.reload

      @tag.destroy if @tag.annotations.blank?

      expire_annotation_fragments

      redirect_to action: :tags
    else
      @all_tags_as_json = TextValue.all.map { |t| { 'id' => t.id, 'name' => h(t.text) } }.to_json
      respond_to do |format|
        format.html
      end
    end
  end

  def delete_tag
    tag = TextValue.find(params[:id])
    if request.post?
      tag.annotations.each do |annotation|
        annotation.destroy
      end
      tag.destroy
      flash.now[:notice] = "Tag #{tag.text} deleted"

    else
      flash.now[:error] = 'Must be a post'
    end

    expire_annotation_fragments

    redirect_to action: :tags
  end

  def get_stats
    collection = []
    type = nil
    title = nil
    @page = params[:id]
    case @page
      when 'pals'
        title = 'PALs'
        collection = Person.pals
        type = 'users'
      when 'admins'
        title = 'Administrators'
        collection = Person.admins
        type = 'users'
      when 'invalid'
        collection = {}
        type = 'invalid_users'
        pal_role = ProjectRole.pal_role
        collection[:pal_mismatch] = Person.all.select { |p| p.is_pal? != p.project_roles.include?(pal_role) }
        collection[:duplicates] = Person.duplicates
        collection[:no_person] = User.without_profile
      when 'not_activated'
        title = 'Users requiring activation'
        collection = User.not_activated
        type = 'users'
      when 'projectless'
        title = "Users not in a #{Seek::Config.project_name} #{t('project')}"
        collection = Person.without_group.registered
        type = 'users'
      when 'contents'
        type = 'content_stats'
      when 'activity'
        type = 'activity_stats'
      when 'search'
        type = 'search_stats'
      when 'job_queue'
        type = 'job_queue'
      when 'auth_consistency'
        type = 'auth_consistency'
      when 'monthly_stats'
        monthly_stats = get_monthly_stats
        type = "monthly_statistics"
      when "workflow_stats"
        type = "workflow_stats"
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
          format.html { render :partial => "admins/content_stats", :locals => {:stats => Seek::Stats::ContentStats.generate} }
        when "activity_stats"
          format.html { render :partial => "admins/activity_stats", :locals => {:stats => Seek::Stats::ActivityStats.new} }
        when "search_stats"
          format.html { render :partial => "admins/search_stats", :locals => {:stats => Seek::Stats::SearchStats.new} }
        when "job_queue"
          format.html { render :partial => "admins/job_queue" }
        when "auth_consistency"
          format.html { render :partial => "admins/auth_consistency" }
        when "monthly_statistics"
          format.html { render :partial => "admins/monthly_statistics", :locals => {:stats => monthly_stats}}
        when "workflow_stats"
          format.html { render :partial => "admins/workflow_stats" }
        when "none"
          format.html { render :text=>"" }
      end
    end
  end

  def get_monthly_stats
    first_month = User.all.sort_by(&:created_at).first.created_at
    number_of_months_since_first = (Date.today.year * 12 + Date.today.month) - (first_month.year * 12 + first_month.month)
    stats = {}
    (0..number_of_months_since_first).each do |x|
      time_range = (x.month.ago.beginning_of_month.to_date..x.month.ago.end_of_month.to_date)
      registrations = User.where(created_at: time_range).count
      active_users = 0
      User.all.each do |user|
        active_users = active_users + 1 unless user.taverna_player_runs.where(created_at: time_range, saved_state: 'finished').empty?
      end
      complete_runs = TavernaPlayer::Run.where(created_at: time_range, saved_state: 'finished').count
      stats[x.month.ago.beginning_of_month.to_i] = [registrations, active_users, complete_runs]
    end
    stats
  end

  def test_email_configuration
    smtp_hash_old = ActionMailer::Base.smtp_settings
    smtp_hash_new = { address: params[:address], enable_starttls_auto: params[:enable_starttls_auto] == '1', domain: params[:domain], authentication: params[:authentication], user_name: (params[:user_name].blank? ? nil : params[:user_name]), password: (params[:password].blank? ? nil : params[:password]) }
    smtp_hash_new[:port] = params[:port] if only_integer params[:port], 'port'
    ActionMailer::Base.smtp_settings = smtp_hash_new
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
        begin
          Mailer.test_email(params[:testing_email]).deliver
          render :update do |page|
            page.replace_html 'ajax_loader_position', "<div id='ajax_loader_position'></div>"
            page.alert("test email is sent successfully to #{params[:testing_email]}")
          end
        rescue => e
          render :update do |page|
            page.replace_html 'ajax_loader_position', "<div id='ajax_loader_position'></div>"
            page.alert("Fail to send test email, #{e.message}")
          end
        ensure
          ActionMailer::Base.smtp_settings = smtp_hash_old
          ActionMailer::Base.raise_delivery_errors = raise_delivery_errors_setting
        end
  end

  private

  def created_at_data_for_model(model)
    x = {}
    start = '1 Nov 2008'

    x[Date.parse(start).jd] = 0
    x[Date.today.jd] = 0

    model.order(:created_at).each do |i|
      date = i.created_at.to_date
      day = date.jd
      x[day] ||= 0
      x[day] += 1
    end
    sorted_keys = x.keys.sort
    (sorted_keys.first..sorted_keys.last).map { |i| x[i].nil? ? 0 : x[i]  }
  end

  def check_valid_email(email_address, field)
    if email_address =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
      return true
    else
      flash[:error] = "Please input the correct #{field}"
      return false
    end
  end

  def only_integer(input, field)
     Integer(input)
     return true
   rescue
     flash[:error] = "Please enter a valid number for the #{field}"
     return false
  end

  def only_positive_integer(input, field)
     if Integer(input) > 0
       return true
     else
       flash[:error] = "Please enter a valid positive number for the #{field}"
       return false
     end
   rescue
     flash[:error] = "Please enter a valid positive number for the #{field}"
     return false
  end

  def string_to_boolean(string)
    if string == '1'
      return true
    else
      return false
    end
  end

  def update_redirect_to(flag, action)
    if flag
      flash[:notice] = RESTART_MSG
      expire_header_and_footer
      redirect_to action: :show
    else
      redirect_to action: action.to_s
    end
  end

  def execute_command(command)
    return nil if Rails.env == 'test'
    begin
      cl = Cocaine::CommandLine.new(command)
      cl.run
      return nil
    rescue Cocaine::CommandNotFoundError => e
      return 'The command the restart the background tasks could not be found!'
    rescue => e
      error =  e.message
      return error
    end
  end

  def redirect_with_status(error, process)
    if error.blank?
      flash[:notice] = "The #{process} was restarted"
    else
      flash[:error] = "There is a problem with restarting the #{process}. #{error.gsub('Cocaine::', '')}"
    end
    redirect_to action: :show
  end
end