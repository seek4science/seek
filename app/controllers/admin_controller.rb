require 'delayed/command'

class AdminController < ApplicationController
  include CommonSweepers

  RESTART_MSG = "Your settings have been updated. If you changed some settings e.g. search, you need to restart some processes.
                 Please see the buttons and explanations below.".freeze

  before_action :login_required
  before_action :is_user_admin_auth

  def index
    respond_to do |format|
      format.html
    end
  end  

  def update_admins
    admin_ids = params[:admins].split(',') || []
    current_admins = Person.admins
    admins = admin_ids.map { |id| Person.find(id) }
    current_admins.each { |ca| ca.is_admin = false }
    admins.each { |admin| admin.is_admin = true }
    (admins | current_admins).each(&:save!)
    redirect_to action: :show
  end

  def registration_form
    respond_to do |format|
      format.html
    end
  end

  def tags
    @tags = TextValue.all_tags.sort_by(&:text)
  end

  def update_features_enabled
    Seek::Config.email_enabled = string_to_boolean params[:email_enabled]
    Seek::Config.pdf_conversion_enabled = string_to_boolean params[:pdf_conversion_enabled]
    # Seek::Config.delete_asset_version_enabled = string_to_boolean params[:delete_asset_version_enabled]
    Seek::Config.project_admin_sample_type_restriction = string_to_boolean params[:project_admin_sample_type_restriction]
    Seek::Config.programme_user_creation_enabled = string_to_boolean params[:programme_user_creation_enabled]
    Seek::Config.managed_programme_id = params[:managed_programme_id]

    Seek::Config.set_smtp_settings('address', params[:address]) if params.key?(:address)
    port_is_integer = true
    if params.key?(:port)
      port = params[:port]
      port_is_integer = only_integer(port, 'port')
      Seek::Config.set_smtp_settings('port', port) if port_is_integer
    end
    Seek::Config.set_smtp_settings('domain', params[:domain]) if params.key?(:domain)
    Seek::Config.set_smtp_settings('authentication', params[:authentication]) if params.key?(:authentication)
    Seek::Config.set_smtp_settings('user_name', params[:smtp_user_name]) if params.key?(:smtp_user_name)
    Seek::Config.set_smtp_settings('password', params[:smtp_password]) if params.key?(:smtp_password)
    Seek::Config.set_smtp_settings('enable_starttls_auto', params[:enable_starttls_auto] == '1') if params.key?(:enable_starttls_auto)

    Seek::Config.support_email_address = params[:support_email_address] if params.key?(:support_email_address)
    Seek::Config.noreply_sender = params[:noreply_sender] if params.key?(:noreply_sender)
    Seek::Config.exception_notification_recipients = params[:exception_notification_recipients] if params.key?(:exception_notification_recipients)
    Seek::Config.exception_notification_enabled = string_to_boolean params[:exception_notification_enabled] if params.key?(:exception_notification_enabled)

    Seek::Config.omniauth_enabled = string_to_boolean params[:omniauth_enabled]
    Seek::Config.omniauth_user_create = string_to_boolean params[:omniauth_user_create]
    Seek::Config.omniauth_user_activate = string_to_boolean params[:omniauth_user_activate]
    Seek::Config.omniauth_ldap_enabled = string_to_boolean params[:omniauth_ldap_enabled]
    Seek::Config.set_omniauth_ldap_settings 'host', params[:omniauth_ldap_host]
    Seek::Config.set_omniauth_ldap_settings 'port', params[:omniauth_ldap_port]&.to_i
    Seek::Config.set_omniauth_ldap_settings 'method', params[:omniauth_ldap_method]&.to_sym
    Seek::Config.set_omniauth_ldap_settings 'base', params[:omniauth_ldap_base]
    Seek::Config.set_omniauth_ldap_settings 'uid', params[:omniauth_ldap_uid]
    Seek::Config.set_omniauth_ldap_settings 'bind_dn', params[:omniauth_ldap_bind_dn]
    Seek::Config.set_omniauth_ldap_settings 'password', params[:omniauth_ldap_password]

    Seek::Config.omniauth_elixir_aai_enabled = string_to_boolean params[:omniauth_elixir_aai_enabled]
    Seek::Config.omniauth_elixir_aai_client_id = params[:omniauth_elixir_aai_client_id]
    Seek::Config.omniauth_elixir_aai_secret = params[:omniauth_elixir_aai_secret]

    Seek::Config.omniauth_github_enabled = string_to_boolean params[:omniauth_github_enabled]
    Seek::Config.omniauth_github_client_id = params[:omniauth_github_client_id]
    Seek::Config.omniauth_github_secret = params[:omniauth_github_secret]

    Seek::Config.solr_enabled = string_to_boolean params[:solr_enabled]
    Seek::Config.filtering_enabled = string_to_boolean params[:filtering_enabled]
    Seek::Config.jws_enabled = string_to_boolean params[:jws_enabled]
    Seek::Config.jws_online_root = params[:jws_online_root]

    Seek::Config.internal_help_enabled = string_to_boolean params[:internal_help_enabled]
    Seek::Config.external_help_url = params[:external_help_url]

    Seek::Config.cwl_viewer_url = params[:cwl_viewer_url]
    Seek::Config.ga4gh_trs_api_enabled = string_to_boolean(params[:ga4gh_trs_api_enabled])
    # Types enabled
    Seek::Config.collections_enabled = string_to_boolean params[:collections_enabled]
    Seek::Config.data_files_enabled = string_to_boolean params[:data_files_enabled]
    Seek::Config.documents_enabled = string_to_boolean params[:documents_enabled]
    Seek::Config.events_enabled = string_to_boolean params[:events_enabled]
    Seek::Config.isa_enabled = string_to_boolean params[:isa_enabled]
    Seek::Config.models_enabled = string_to_boolean params[:models_enabled]
    Seek::Config.organisms_enabled = string_to_boolean params[:organisms_enabled]
    Seek::Config.programmes_enabled = string_to_boolean params[:programmes_enabled]
    Seek::Config.programmes_open_for_projects_enabled = string_to_boolean params[:programmes_open_for_projects_enabled]
    Seek::Config.presentations_enabled = string_to_boolean params[:presentations_enabled]
    Seek::Config.publications_enabled = string_to_boolean params[:publications_enabled]
    Seek::Config.samples_enabled = string_to_boolean params[:samples_enabled]
    Seek::Config.sops_enabled = string_to_boolean params[:sops_enabled]
    Seek::Config.workflows_enabled = string_to_boolean params[:workflows_enabled]

    Seek::Config.google_analytics_tracker_id = params[:google_analytics_tracker_id]
    Seek::Config.google_analytics_enabled = string_to_boolean params[:google_analytics_enabled]
    Seek::Config.google_analytics_tracking_notice = params[:google_analytics_tracking_notice]

    Seek::Config.piwik_analytics_enabled = string_to_boolean params[:piwik_analytics_enabled]
    Seek::Config.piwik_analytics_id_site = params[:piwik_analytics_id_site]
    Seek::Config.piwik_analytics_url = params[:piwik_analytics_url]
    Seek::Config.piwik_analytics_tracking_notice = params[:piwik_analytics_tracking_notice]

    Seek::Config.doi_minting_enabled = string_to_boolean params[:doi_minting_enabled]
    Seek::Config.datacite_username = params[:datacite_username]
    Seek::Config.datacite_password = params[:datacite_password]
    Seek::Config.datacite_url = params[:datacite_url]
    Seek::Config.doi_prefix = params[:doi_prefix]
    Seek::Config.doi_suffix = params[:doi_suffix]

    Seek::Config.zenodo_publishing_enabled = string_to_boolean params[:zenodo_publishing_enabled]
    Seek::Config.zenodo_api_url = params[:zenodo_api_url]
    Seek::Config.zenodo_oauth_url = params[:zenodo_oauth_url]
    Seek::Config.zenodo_client_id = params[:zenodo_client_id].try(:strip)
    Seek::Config.zenodo_client_secret = params[:zenodo_client_secret].try(:strip)

    Seek::Config.openbis_enabled = string_to_boolean(params[:openbis_enabled])
    Seek::Config.copasi_enabled = string_to_boolean(params[:copasi_enabled])
    Seek::Config.project_single_page_enabled = string_to_boolean(params[:project_single_page_enabled])
    Seek::Config.sample_type_template_enabled = string_to_boolean(params[:sample_type_template_enabled])

    Seek::Config.nels_enabled = string_to_boolean(params[:nels_enabled])
    Seek::Config.nels_client_id = params[:nels_client_id]&.strip
    Seek::Config.nels_client_secret = params[:nels_client_secret]&.strip
    Seek::Config.nels_api_url = params[:nels_api_url]&.strip&.chomp('/')
    Seek::Config.nels_oauth_url = params[:nels_oauth_url]&.strip&.chomp('/')
    Seek::Config.nels_permalink_base = params[:nels_permalink_base]&.strip

    Seek::Config.life_monitor_enabled = string_to_boolean(params[:life_monitor_enabled])
    Seek::Config.life_monitor_url = params[:life_monitor_url]&.strip&.chomp('/')
    Seek::Config.life_monitor_client_id = params[:life_monitor_client_id]&.strip
    Seek::Config.life_monitor_client_secret = params[:life_monitor_client_secret]&.strip

    time_lock_doi_for = params[:time_lock_doi_for]
    time_lock_is_integer = only_integer time_lock_doi_for, 'time lock doi for'
    Seek::Config.time_lock_doi_for = time_lock_doi_for.to_i if time_lock_is_integer

    Seek::Util.clear_cached

    validation_flag = time_lock_is_integer && port_is_integer
    update_redirect_to validation_flag, 'features_enabled'
  end

  def update_home_settings
    Seek::Config.show_announcements = string_to_boolean params[:show_announcements]
    Seek::Config.news_enabled = string_to_boolean params[:news_enabled]
    Seek::Config.news_feed_urls = params[:news_feed_urls]

    entries = params[:news_number_of_entries]
    is_entries_integer = only_integer entries, 'news items'
    Seek::Config.news_number_of_entries = entries if is_entries_integer

    Seek::Config.home_description = params[:home_description]

    #    Seek::Config.front_page_buttons_enabled = params[:front_page_buttons_enabled]

    Seek::Config.home_show_features = string_to_boolean params[:home_show_features]
    Seek::Config.home_show_quickstart = string_to_boolean params[:home_show_quickstart]
    Seek::Config.home_show_my_items = string_to_boolean params[:home_show_my_items]
    Seek::Config.home_show_who_uses = string_to_boolean params[:home_show_who_uses]
    Seek::Config.home_explore_projects = string_to_boolean params[:home_explore_projects]
    Seek::Config.home_show_integrations = string_to_boolean params[:home_show_integrations]
    add_carousel_form

    begin
      Seek::FeedReader.clear_cache
    rescue => e
      logger.error "Error whilst attempting to clear feed cache #{e.message}"
    end

    max_visible_tags = params[:max_visible_tags]
    tag_threshold = params[:tag_threshold]
    Seek::Config.tag_threshold = tag_threshold if only_integer tag_threshold, 'tag threshold'
    Seek::Config.max_visible_tags = max_visible_tags if only_positive_integer max_visible_tags, 'maximum visible tags'
    Seek::Config.tag_cloud_enabled = string_to_boolean params[:tag_cloud_enabled]
    Seek::Config.workflow_class_list_enabled = string_to_boolean params[:workflow_class_list_enabled]

    update_redirect_to (is_entries_integer && (only_integer tag_threshold, 'tag threshold') && (only_positive_integer max_visible_tags, 'maximum visible tags')), 'home_settings'
  end

  def rebrand
    respond_to do |format|
      format.html
    end
  end

  def update_rebrand
    Seek::Config.instance_name = params[:instance_name]
    Seek::Config.instance_link = params[:instance_link]
    Seek::Config.instance_description = params[:instance_description]
    Seek::Config.instance_keywords = params[:instance_keywords].split(',').collect(&:strip).reject(&:blank?).join(', ')

    Seek::Config.instance_admins_name = params[:instance_admins_name]
    Seek::Config.instance_admins_link = params[:instance_admins_link]
    Seek::Config.issue_tracker = params[:issue_tracker]

    Seek::Config.header_image_enabled = string_to_boolean params[:header_image_enabled]
    Seek::Config.header_image_link = params[:header_image_link]
    Seek::Config.header_image_title = params[:header_image_title]
    header_image_file

    Seek::Config.copyright_addendum_enabled = string_to_boolean params[:copyright_addendum_enabled]
    Seek::Config.copyright_addendum_content = params[:copyright_addendum_content]

    Seek::Config.imprint_enabled = string_to_boolean params[:imprint_enabled]
    Seek::Config.imprint_description = params[:imprint_description]

    Seek::Config.about_page_enabled = string_to_boolean params[:about_page_enabled]
    Seek::Config.about_page = params[:about_page]

    Seek::Config.about_instance_link_enabled = string_to_boolean params[:about_instance_link_enabled]
    Seek::Config.about_instance_admins_link_enabled = string_to_boolean params[:about_instance_admins_link_enabled]
    Seek::Config.cite_link = params[:cite_link]
    Seek::Config.contact_link = params[:contact_link]

    Seek::Config.funding_link = params[:funding_link]

    Seek::Config.terms_enabled = string_to_boolean params[:terms_enabled]
    Seek::Config.terms_page = params[:terms_page]


    Seek::Config.privacy_enabled = string_to_boolean params[:privacy_enabled]
    Seek::Config.privacy_page = params[:privacy_page]

    update_redirect_to true, 'rebrand'
  end

  def update_pagination
    %w[people projects projects programmes institutions investigations
        studies assays data_files models sops publications presentations events documents].each do |type|
      Seek::Config.set_sorting_for(type, params[:sorting][type])
      Seek::Config.set_results_per_page_for(type, params[:results_per_page][type])
    end

    valid = only_positive_integer(params[:results_per_page_default], 'default items per page')
    Seek::Config.results_per_page_default = params[:results_per_page_default] if valid

    valid_condensed = only_positive_integer(params[:results_per_page_default_condensed], 'default items per condensed page')
    Seek::Config.results_per_page_default_condensed = params[:results_per_page_default_condensed] if valid_condensed

    Seek::Config.related_items_limit = params[:related_items_limit]
    Seek::Config.search_results_limit = params[:search_results_limit]

    update_redirect_to(valid, 'pagination')
  end

  def update_settings
    if Seek::Config.tag_threshold.to_s != params[:tag_threshold] || Seek::Config.max_visible_tags.to_s != params[:max_visible_tags]
      expire_annotation_fragments
    end
    Seek::Config.site_base_host = params[:site_base_host].chomp('/') unless params[:site_base_host].nil?
    # check valid email
    pubmed_email = params[:pubmed_api_email]
    pubmed_email_valid = check_valid_email(pubmed_email, 'pubmed API email address')
    crossref_email = params[:crossref_api_email]
    crossref_email_valid = check_valid_email(crossref_email, 'crossref API email address')
    Seek::Config.allow_publications_fulltext = string_to_boolean params[:allow_publications_fulltext]
    Seek::Config.allow_edit_of_registered_publ = string_to_boolean params[:allow_edit_of_registered_publ]
    Seek::Config.pubmed_api_email = pubmed_email if pubmed_email == '' || pubmed_email_valid
    Seek::Config.crossref_api_email = crossref_email if crossref_email == '' || crossref_email_valid

    Seek::Config.bioportal_api_key = params[:bioportal_api_key]
    Seek::Config.sabiork_ws_base_url = params[:sabiork_ws_base_url] unless params[:sabiork_ws_base_url].nil?
    Seek::Config.recaptcha_enabled = string_to_boolean params[:recaptcha_enabled]
    Seek::Config.recaptcha_private_key = params[:recaptcha_private_key]
    Seek::Config.recaptcha_public_key = params[:recaptcha_public_key]
    Seek::Config.default_associated_projects_access_type = params[:default_associated_projects_access_type]
    Seek::Config.default_all_visitors_access_type = params[:default_all_visitors_access_type]
    Seek::Config.max_all_visitors_access_type = params[:max_all_visitors_access_type]
    Seek::Config.permissions_popup = params[:permissions_popup]
    Seek::Config.auth_lookup_update_batch_size = params[:auth_lookup_update_batch_size]

    Seek::Config.allow_private_address_access = string_to_boolean params[:allow_private_address_access]
    Seek::Config.cache_remote_files = string_to_boolean params[:cache_remote_files]
    Seek::Config.max_cachable_size = params[:max_cachable_size]
    Seek::Config.hard_max_cachable_size = params[:hard_max_cachable_size]

    Seek::Config.hide_details_enabled = string_to_boolean params[:hide_details_enabled]
    Seek::Config.registration_disabled = string_to_boolean params[:registration_disabled]
    Seek::Config.registration_disabled_description = params[:registration_disabled_description]
    Seek::Config.activation_required_enabled = string_to_boolean params[:activation_required_enabled]
    Seek::Config.orcid_required = string_to_boolean params[:orcid_required]

    Seek::Config.default_license = params[:default_license]
    Seek::Config.recommended_data_licenses = params[:recommended_data_licenses]
    Seek::Config.recommended_software_licenses = params[:recommended_software_licenses]
    update_flag = (pubmed_email == '' || pubmed_email_valid) && (crossref_email == '' || crossref_email_valid)
    update_redirect_to update_flag, 'settings'
  end

  def restart_server
    command = "touch #{Rails.root}/tmp/restart.txt"
    error = execute_command(command)
    redirect_with_status(error, 'server')
  end

  def restart_delayed_job
    error = nil
    unless Rails.env.test?
      begin
        Seek::Workers.restart
        wait_for_delayed_job_to_start
      rescue SystemExit => e
        Rails.logger.info("Exit code #{e.status}")
      rescue => e
        Seek::Errors::ExceptionForwarder.send_notification(e, data:{message:'Problem restarting delayed job'})
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

      if params[:tag_list].blank?
        flash[:error] = 'Not tags provided, use Delete to delete a tag. Make sure you register the replacement tag by pressing comma'
        respond_to do |format|
          format.html { render status: :not_acceptable }
        end
      else
        params[:tag_list].split(',').each do |item|
          item.strip!
          tag = TextValue.find_by_text(item)
          tag = TextValue.create(text: item) if tag.nil? || tag.text != item # case sensitivity check
          replacement_tags << tag
        end

        @tag.annotations.each do |a|
          annotatable = a.annotatable
          source = a.source
          attribute_name = a.annotation_attribute.name
          a.destroy unless replacement_tags.include?(@tag)
          replacement_tags.each do |tag|
            if annotatable.annotations_with_attribute_and_by_source(attribute_name, source).select { |an| an.value == tag }.blank?
              new_annotation = Annotation.new attribute_name: attribute_name, value: tag, annotatable: annotatable, source: source
              new_annotation.save!
            end
          end
          expire_resource_list_item_content(annotatable) if annotatable
        end

        @tag.reload

        @tag.destroy if @tag.annotations.blank?

        expire_annotation_fragments

        redirect_to action: :tags
      end

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
      tag.annotations.each(&:destroy)
      tag.destroy
      flash.now[:notice] = "Tag #{tag.text} deleted"

    else
      flash.now[:error] = 'Must be a post'
    end

    expire_annotation_fragments

    redirect_to action: :tags
  end

  def get_stats
    @page = params[:page]
      case @page
      when 'content_stats'
        render partial: 'admin/stats/content_stats', locals: { stats: Seek::Stats::ContentStats.generate }
      when 'activity_stats'
        render partial: 'admin/stats/activity_stats', locals: { stats: Seek::Stats::ActivityStats.new }
      when 'search_stats'
        render partial: 'admin/stats/search_stats', locals: { stats: Seek::Stats::SearchStats.new }
      when 'job_queue'
        render partial: 'admin/stats/job_queue'
      when 'auth_consistency'
        render partial: 'admin/stats/auth_consistency'
      when 'storage_usage_stats'
        render partial: 'admin/stats/storage_usage_stats'
      when 'snapshot_and_doi_stats'
        render partial: 'admin/stats/snapshot_and_doi_stats'
      when 'none'
        render html: ''
      else
        get_user_stats
    end
  end

  def get_user_stats
    partial = nil
    collection = []
    action = nil
    title = nil
    extra_options = {}
    case @page
    when 'invalid_users_profiles'
      partial = 'invalid_user_stats_list'
      invalid_users = {}
      pal_position = ProjectPosition.pal_position
      invalid_users[:pal_mismatch] = Person.all.reject { |p| p.is_pal_of_any_project? == p.project_positions.include?(pal_position) }
      invalid_users[:duplicates] = Person.duplicates
      invalid_users[:no_person] = User.without_profile
      collection = invalid_users
    when 'users_requiring_activation'
      partial = 'user_stats_list'
      collection = User.not_activated
      action = 'activate'
      title = 'Users have not yet activated their account'
    when 'non_project_members'
      partial = 'user_stats_list'
      collection = Person.without_group.registered
      title = "Users are not in a #{Seek::Config.instance_name} #{t('project')}"
    when 'profiles_without_users'
      partial = 'user_stats_list'
      collection = Person.userless_people
      title = 'Profiles that have no associated user'
      extra_options = { action: 'delete', bulk_delete: false }
    when 'pals'
      partial = 'user_stats_list'
      collection = Person.pals
      title = 'List of PALs'
    when 'none'
      partial = 'none'
    end
    respond_to do |format|
      if partial == 'none'
        format.html { render html: '' }
      else
        locals = { collection: collection, action: action, title: title }.merge(extra_options)
        format.html { render partial: partial, locals: locals }
      end
    end
  end

  def test_email_configuration
    smtp_hash_old = ActionMailer::Base.smtp_settings
    smtp_hash_new = { address: params[:address],
                      enable_starttls_auto: params[:enable_starttls_auto] == '1',
                      domain: params[:domain],
                      authentication: params[:authentication],
                      user_name: (params[:smtp_user_name].blank? ? nil : params[:smtp_user_name]),
                      password: (params[:smtp_password].blank? ? nil : params[:smtp_password]) }
    smtp_hash_new[:port] = params[:port] if only_integer params[:port], 'port'
    ActionMailer::Base.smtp_settings = smtp_hash_new
    raise_delivery_errors_setting = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
    begin
      mail = Mailer.test_email(params[:testing_email])
      if params[:deliver_later]
        mail.deliver_later
        render json: { message: "Test email to #{params[:testing_email]} was added to the queue."}, status: :ok
      else
        mail.deliver_now
        render json: { message: "Test email sent successfully to #{params[:testing_email]}."}, status: :ok
      end
    rescue => e
      render json: { error: "Fail to send test email, #{e.message}"}, status: :internal_server_error
    ensure
      ActionMailer::Base.smtp_settings = smtp_hash_old
      ActionMailer::Base.raise_delivery_errors = raise_delivery_errors_setting
    end
  end

  def header_image_file
    if params[:header_image_file]
      file_io = params[:header_image_file]
      avatar = Avatar.new(original_filename: file_io.original_filename, image_file: file_io, skip_owner_validation: true)
      if avatar.save
        Seek::Config.header_image_avatar_id = avatar.id
      else
        flash[:error] = 'There was an error updating the header image logo! There could be a problem with the image file. Please try again or try another image.'
      end
    end
  end

  def add_carousel_form
    # Only add it if at least logo and title is given carousel inputs are filled
    if (!params[:home_carousel_image].blank? && !params[:home_carousel_title].blank?)
      file_io = params[:home_carousel_image]
      avatar = Avatar.new(original_filename: file_io.original_filename, image_file: file_io, skip_owner_validation: true)
      if avatar.save
        if Seek::Config.home_carousel.blank?
          Seek::Config.home_carousel = Array.new
        end
        # build new data to store
        data = {:image => avatar.id, :title => params[:home_carousel_title],
          :author => params[:home_carousel_author], :url => params[:home_carousel_url],
          :description => params[:home_carousel_description]}
        Seek::Config.home_carousel = Seek::Config.home_carousel << data
      else
        flash[:error] = 'There was an error adding an image to the carousel! There could be a problem with the image file. Please try again or try another image.'
      end
    # else
    #   flash[:error] = 'Information was missing for the carousel configuration, no changes has been made to it.'
    end
  end

  # Removes the carousel item with the given image id
  def delete_carousel_form
    carousel_index = Integer(params[:carousel_index], exception: false)
    if carousel_index && request.post?
      image_id = Seek::Config.home_carousel[carousel_index][:image]
      Seek::Config.home_carousel = array_remove_at(Seek::Config.home_carousel,carousel_index)
      Avatar.find(image_id).delete
      flash.now[:notice] = "Carousel number #{carousel_index} deleted"
    else
      flash.now[:error] = 'Must be a post'
    end
    redirect_to :home_settings_admin
  end

  ## Helper function to retrieve arrays removing a given index
  def array_remove_at(array, index)
    if index<0 || index>=array.length
      return array
    end
    return array.slice(0,index) + array.slice(index+1,array.length)
  end

  # this destroys any failed Delayed::Jobs
  def clear_failed_jobs
    Delayed::Job.where('failed_at IS NOT NULL').destroy_all
    respond_to do |format|
      format.json { head :ok }
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
    (sorted_keys.first..sorted_keys.last).map { |i| x[i].nil? ? 0 : x[i] }
  end

  def check_valid_email(email_address, field)
    if email_address.blank? || email_address =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
      true
    else
      flash[:error] = "Please input a valid #{field}"
      false
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
      true
    else
      false
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
    return nil if Rails.env.test?
    begin
      cl = Terrapin::CommandLine.new(command)
      cl.run
      return nil
    rescue Terrapin::CommandNotFoundError => e
      return 'The command to restart the background tasks could not be found!'
    rescue => e
      error = e.message
      return error
    end
  end

  def redirect_with_status(error, process)
    if error.blank?
      flash[:notice] = "The #{process} was restarted"
    else
      flash[:error] = "There is a problem with restarting the #{process}. #{error.gsub('Terrapin::', '')}"
    end
    redirect_to action: :show
  end

end
