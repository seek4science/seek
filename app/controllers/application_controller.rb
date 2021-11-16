# coding: utf-8
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'authenticated_system'

class ApplicationController < ActionController::Base
  include Seek::Errors::ControllerErrorHandling
  include Seek::EnabledFeaturesFilter
  include Recaptcha::Verify

  include CommonSweepers

  # if the logged in user is currently partially registered, force the continuation of the registration process
  before_action :partially_registered?

  before_action :check_displaying_single_page

  after_action :log_event

  include AuthenticatedSystem

  around_action :with_current_user

  rescue_from 'ActiveRecord::RecordNotFound', with: :render_not_found_error
  rescue_from 'ActiveRecord::UnknownAttributeError', with: :render_unknown_attribute_error
  rescue_from NotImplementedError, with: :render_not_implemented_error

  before_action :project_membership_required, only: [:create, :new]

  before_action :restrict_guest_user, only: [:new, :edit, :batch_publishing_preview]

  before_action :check_doorkeeper_scopes, if: :doorkeeper_token
  before_action :check_json_id_type, only: [:create, :update], if: :json_api_request?
  before_action :convert_json_params, only: [:update, :destroy, :create, :create_version], if: :json_api_request?

  before_action :rdf_enabled? #only allows through rdf calls to supported types

  helper :all

  layout Seek::Config.main_layout

  def with_current_user
    User.with_current_user current_user do
      yield
    end
  end

  def current_person
    current_user.try(:person)
  end

  def partially_registered?
    redirect_to register_people_path if current_user && !current_user.registration_complete?
  end

  def strip_root_for_xml_requests
    # intended to use as a before filter on requests that lack a single root model.
    # XML requests are required to have a single root node. This assumes the root node
    # will be named xml. Turns a params hash like.. {:xml => {:param_one => "val", :param_two => "val2"}}
    # into {:param_one => "val", :param_two => "val2"}

    # This should probably be used with prepend_before_action, since some filters might need this to happen so they can check params.
    # see sessions controller for an example usage
    params[:xml].each { |k, v| params[k] = v } if request.format.xml? && params[:xml]
  end

  def set_no_layout
    self.class.layout nil
  end

  def base_host
    request.host_with_port
  end

  def api_version
    @default = 1
    version_re_arr = [/version=(?<v>.+?)/, /api.v(?<v>\d+?)\+json/]
    version_re_arr.each do |re|
      v_match = request.headers['Accept'].match(re)
      if (v_match  != nil)
        @version = v_match[:v]
        break
      end
    end
    @version ||= @default
  end

  def is_current_user_auth
    if current_user.nil? || params[:id].to_s != current_user.id.to_s
      error('User not found (or not authorized)', 'is invalid (not owner)')
      false
    else
      @user = current_user
    end
  end

  def is_user_admin_auth
    unless User.admin_logged_in?
      error('Admin rights required', 'is invalid (not admin)', :forbidden)
      return false
    end
    true
  end

  def can_manage_announcements?
    admin_logged_in?
  end

  def admin_logged_in?
    User.admin_logged_in?
  end

  def logout_user
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
  end


  def page_and_sort_params
    permitted = Seek::Filterer.new(controller_model).available_filter_keys.flat_map { |p| [p, { p => [] }] }
    permitted_filter_params = { filter: permitted }
    params.permit(:page, :sort, :order, :view, :table_cols, permitted_filter_params)
  end

  helper_method :page_and_sort_params

  def controller_model
    begin
      @controller_model ||= controller_name.classify.constantize
    rescue NameError
    end
  end

  helper_method :controller_model

  def self.api_actions(*actions)
    @api_actions ||= (superclass.respond_to?(:api_actions) ? superclass.api_actions.dup : []) + actions.map(&:to_sym)
  end

  private

  # returns the model asset assigned to the standard object for that controller, e.g. @model for models_controller
  def determine_asset_from_controller
    name = controller_name.singularize
    instance_variable_get("@#{name}")
  end

  def restrict_guest_user
    if current_user && current_user.guest?
      flash[:error] = 'You cannot perform this action as a Guest User. Please sign in or register for an account first.'
      redirect_back fallback_location: main_app.root_path
    end
  end

  def project_membership_required
    unless User.logged_in_and_member? || admin_logged_in?
      flash[:error] = "Only members of #{t('project').downcase.pluralize} can create content."
      respond_to do |format|
        format.html do
          object = determine_asset_from_controller
          if !object.nil? && object.try(:can_view?)
            redirect_to object
          else
            path = nil
            begin
              path = main_app.polymorphic_path(controller_name)
            rescue NoMethodError => e
              logger.error("No path found for controller - #{controller_name}")
              path = main_app.root_path
            end
            redirect_to path
          end
        end
        format.json { render json: {"title": "Unauthorized", "detail": flash[:error].to_s}, status: :unauthorized}
        format.js { render json: {"title": "Unauthorized", "detail": flash[:error].to_s}, status: :unauthorized}
      end
    end
  end

  alias_method :project_membership_required_appended, :project_membership_required

  # used to suppress elements that are for virtualliver only or are still currently being worked on
  def virtualliver_only
    unless Seek::Config.is_virtualliver
      error('This feature is is not yet currently available', 'invalid route')
      return false
    end
  end

  def check_allowed_to_manage_types
    unless Seek::Config.type_managers_enabled
      error('Type management disabled', '...')
      return false
    end
    if current_user
      if current_user.can_manage_types?
        return true
      else
        error('Admin rights required to manage types', '...')
        return false
      end
    else
      error('You need to login first.', '...')
      return false
    end
  end

  #_status is mostly important for the json responses, default is 400 (Bad Request)
  def error(notice, message, status=400)
    flash[:error] = notice
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: { errors: [{ title: notice, detail: message }] }, status:  status }
    end
  end

  # handles finding an asset, and responding when it cannot be found. If it can be found the item instance is set (e.g. @project for projects_controller)
  def find_requested_item
    name = controller_name.singularize
    object = name.camelize.constantize.find_by_id(params[:id])
    if object.nil?
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.rdf { render plain: 'Not found', status: :not_found }
        format.xml { render xml: '<error>404 Not found</error>', status: :not_found }
        format.json { render json: { errors: [{ title: 'Not found',
                                                detail: "Couldn't find #{name.camelize} with 'id'=[#{params[:id]}]" }] },
                             status: :not_found }
        format.html { redirect_to polymorphic_path(controller_name) }
      end
    else
      instance_variable_set("@#{name}", object)
    end
  end

  # handles finding and authorizing an asset for all controllers that require authorization, and handling if the item cannot be found
  def find_and_authorize_requested_item
    name = controller_name.singularize
    privilege = Seek::Permissions::Translator.translate(action_name)

    return if privilege.nil?

    object = controller_model.find(params[:id])

    if is_auth?(object, privilege)
      instance_variable_set("@#{name}", object)
      params.delete :policy_attributes unless object.can_manage?(current_user)
    else
      respond_to do |format|
        format.html do
          case privilege
          when :publish, :manage, :edit, :download, :delete
            if current_user.nil?
              flash[:error] = "You are not authorized to #{privilege} this #{name.humanize}, you may need to login first."
            else
              flash[:error] = "You are not authorized to #{privilege} this #{name.humanize}."
            end
            handle_authorization_failure_redirect(object, privilege)
          else
            render template: 'general/landing_page_for_hidden_item', locals: { item: object }, status: :forbidden
          end
        end
        format.rdf { render plain: "You may not #{privilege} #{name}:#{params[:id]}", status: :forbidden }
        format.xml { render plain: "<error>You may not #{privilege} #{name}:#{params[:id]}</error>", status: :forbidden }
        format.json { render json: { errors: [{ title: 'Forbidden',
                                                details: "You may not #{privilege} #{name}:#{params[:id]}" }] },
                             status: :forbidden }
      end
      return false
    end
  end

  def handle_authorization_failure_redirect(object, privilege)
    redirect_to(object)
  end

  def auth_to_create
    unless controller_model.can_create?
      error('You do not have permission', 'No permission')
      return false
    end
  end

  def render_not_found_error(e)
    respond_to do |format|
      format.html do
        User.with_current_user current_user do
          render template: 'general/landing_page_for_not_found_item', status: :not_found
        end
      end

      format.rdf { render plain: 'Not found', status: :not_found }
      format.xml { render xml: '<error>404 Not found</error>', status: :not_found }
      format.json { render json: { errors: [{ title: 'Not found', detail: e.message }] }, status: :not_found }
    end
    false
  end

  def render_unknown_attribute_error(e)
    respond_to do |format|
      format.json { render json: { errors: [{ title: 'Unknown attribute', details: e.message }] }, status: :unprocessable_entity }
      format.all { render plain: e.message, status: :unprocessable_entity }
    end
  end

  def render_not_implemented_error(e)
    respond_to do |format|
      format.json { render json: { errors: [{ title: 'Not implemented', details: e.message }] }, status: :not_implemented }
      format.all { render plain: e.message, status: :not_implemented }
    end
  end

  def is_auth?(object, privilege)
    if object.can_perform?(privilege)
      true
    elsif params[:code] && [:view, :download].include?(privilege)
      object.auth_by_code?(params[:code])
    else
      false
    end
  end

  # Checks whether the current view is "condensed" (short results or table)
  def is_condensed_view?
    # Check current view from param, or on its absence from session
    return (params.has_key?(:view) && params[:view]!="default")||
      (!params.has_key?(:view) && session.has_key?(:view) && !session[:view].nil? && session[:view]!="default")
  end
  
  helper_method :is_condensed_view


  def log_event
    # FIXME: why is needed to wrap in this block when the around filter already does ?
    User.with_current_user current_user do
      controller_name = self.controller_name.downcase
      action = action_name.downcase

      object = object_for_request

      object = current_user if controller_name == 'sessions' # logging in and out is a special case

      # don't log if the object is not valid or has not been saved, as this will a validation error on update or create
      return if object_invalid_or_unsaved?(object)

      user_agent = request.env['HTTP_USER_AGENT']

      case controller_name
      when 'sessions'
        if %w(create destroy).include?(action)
          ActivityLog.create(action: action,
                             culprit: current_user,
                             controller_name: controller_name,
                             activity_loggable: object,
                             user_agent: user_agent)
        end
      when 'people', 'projects', 'institutions'
        if %w(show create update destroy).include?(action)
          ActivityLog.create(action: action,
                             culprit: current_user,
                             controller_name: controller_name,
                             activity_loggable: object,
                             data: object.title,
                             user_agent: user_agent)
        end
      when 'search'
        if action == 'index'
          ActivityLog.create(action: 'index',
                             culprit: current_user,
                             controller_name: controller_name,
                             user_agent: user_agent,
                             data: { search_query: object, result_count: @results.count })
        end
      when 'content_blobs'
        # action download applies for normal download
        # action inline_view applies for viewing image and pdf file in browser
        action = 'inline_view' if action == 'view_content' # view pdf
        action = 'inline_view' if action == 'download' && params['disposition'].to_s == 'inline' # view image

        # when viewing pdf content, first it goes to 'view_content' action, then 'download' action, with intent = 'inline_view'
        # so do not log the 'download' action in this case
        # just making a fake action here
        action = 'feed_pdf_inline_view' if action == 'download' && params['intent'].to_s == 'inline_view'
        if %w(download inline_view).include?(action)
          activity_loggable = object.asset
          ActivityLog.create(action: action,
                             culprit: current_user,
                             referenced: object,
                             controller_name: controller_name,
                             activity_loggable: activity_loggable,
                             user_agent: user_agent,
                             data: activity_loggable.title)
        end
      when *Seek::Util.authorized_types.map { |t| t.name.underscore.pluralize.split('/').last } + ["sample_types"] # TODO: Find a nicer way of doing this...
        action = 'create' if action == 'upload_for_tool' || action == 'create_metadata' || action == 'create_from_template'
        action = 'update' if action == 'create_version'
        action = 'inline_view' if action == 'explore'
        if %w(show create update destroy download inline_view).include?(action)
          check_log_exists(action, controller_name, object)
            ActivityLog.create(action: action,
                             culprit: current_user,
                             referenced: object.projects.first,
                             controller_name: controller_name,
                             activity_loggable: object,
                             data: object.title,
                             user_agent: user_agent)
        end
      when 'snapshots'
        if %(show create mint_doi_confirm download export_submit).include?(action)
          ActivityLog.create(action: action,
                             culprit: current_user,
                             referenced: object.resource,
                             controller_name: controller_name,
                             activity_loggable: object,
                             data: object.title,
                             user_agent: user_agent)
        end
      end

      expire_activity_fragment_cache(controller_name, action)
    end
  end

  def object_invalid_or_unsaved?(object)
    object.nil? || (object.respond_to?('new_record?') && object.new_record?) || (object.respond_to?('errors') && !object.errors.empty?)
  end

  # determines and returns the object related to controller, e.g. @data_file
  def object_for_request
    instance_variable_get("@#{controller_name.singularize}")
  end

  def expire_activity_fragment_cache(controller, action)
    if action != 'show'
      @@auth_types ||= Seek::Util.authorized_types.collect { |t| t.name.underscore.pluralize }
      if action == 'download'
        expire_download_activity
      elsif action == 'create' && controller != 'sessions'
        expire_create_activity
      elsif action == 'destroy' && controller != 'sessions'
        expire_create_activity
        expire_download_activity
      elsif action == 'update' && @@auth_types.include?(controller) # may have had is permission changed
        expire_create_activity
        expire_download_activity
        expire_resource_list_item_action_partial
      end
    end
  end

  def check_log_exists(action, controllername, object)
    if action == 'create'
      a = ActivityLog.where(
        activity_loggable_type: object.class.name,
        activity_loggable_id: object.id,
        controller_name: controllername,
        action: 'create').first

      logger.error("ERROR: Duplicate create activity log about to be created for #{object.class.name}:#{object.id}") unless a.nil?
    end
  end

  # checks if a captcha has been filled out correctly, if enabled, and returns false if not
  def check_captcha
    if Seek::Config.recaptcha_setup?
      verify_recaptcha
    else
      true
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:user_agent] = request.user_agent
  end

  def redirect_to_sign_up_when_no_user
    redirect_to signup_path if User.count == 0
  end

  # Non-ascii-characters are escaped, even though the response is utf-8 encoded.
  # This method will convert the escape sequences back to characters, i.e.: "\u00e4" -> "ä" etc.
  # from https://stackoverflow.com/questions/5123993/json-encoding-wrongly-escaped-rails-3-ruby-1-9-2
  # by steffen.brinkmann@h-its.org
  # 2017-04-18
#  def unescape_response()
#    response_body[0].gsub!(/\\u([0-9a-z]{4})/) { |s|
#      [$1.to_i(16)].pack("U")
#    }
#  end

  def policy_params
    params.slice(:policy_attributes).permit(
        policy_attributes: [:access_type,
                            { permissions_attributes: [:access_type,
                                                       :contributor_type,
                                                       :contributor_id] }])[:policy_attributes] || {}
  end

  def check_json_id_type
    begin
      raise ArgumentError.new('A POST/PUT request must have a data record complying with JSONAPI specs') if params[:data].nil?
      #type should always appear in POST or PUT requests
      if params[:data][:type].nil?
        raise ArgumentError.new('A POST/PUT request must specify a data:type')
      elsif params[:data][:type] != params[:controller]
        raise ArgumentError.new("The specified data:type does not match the URL's object (#{params[:data][:type]} vs. #{params[:controller]})")
      end
      #id should not appear on POST, but should be accurate IF it appears on PUT
      case params[:action]
        when "create"
          if !params[:data][:id].nil?
            raise ArgumentError.new('A POST request is not allowed to specify an id')
          end
        when "update"
          if (!params[:data][:id].nil?) && (params[:id].to_s != params[:data][:id].to_s)
            raise ArgumentError.new('id specified by the PUT request does not match object-id in the JSON input')
          end
      end
    rescue ArgumentError => e
      output = "{\"errors\" : [{\"detail\" : \"#{e.message}\"}]}"
      render plain: output, status: :unprocessable_entity
    end
  end

  def convert_json_params
    Seek::Api::ParameterConverter.new(controller_name, param_converter_options).convert(params)
  end

  def json_api_request?
    request.format.json?
  end

  # filter that responds with :not_acceptable if request rdf for non rdf capable resource
  def rdf_enabled?
    return unless request.format.rdf?
    unless Seek::Util.rdf_capable_types.include?(controller_model)
      respond_to do |format|
        format.rdf { render plain: 'This resource does not support RDF', status: :not_acceptable, content_type: 'text/plain' }
      end
    end
  end

  def json_api_errors(object)
    hash = { errors: [] }
    hash[:errors] = object.errors.map do |attribute, message|
      segments = attribute.to_s.split('.')
      attr = segments.first
      if !['content_blobs', 'policy'].include?(attr) && object.class.reflect_on_association(attr)
        base = '/data/relationships'
      else
        base = '/data/attributes'
      end

      {
          source: { pointer: "#{base}/#{attr}" },
          detail: "#{segments[1..-1].join(' ') + ' ' if segments.length > 1}#{message}"
      }
    end

    hash
  end

  def param_converter_options
    {}
  end

  def check_doorkeeper_scopes
    if self.class.api_actions.include?(action_name.to_sym)
      privilege = Seek::Permissions::Translator.translate(action_name)
      scopes = [:view, :download].include?(privilege) ? [:read, :write] : [:write]
      doorkeeper_authorize!(*scopes)
    else
      respond_to do |format|
        format.html { render plain: 'This action is not permitted for API clients using OAuth.', status: :forbidden }
        format.json { render json: {
            errors: [{ title: 'Forbidden',
                       details: 'This action is not permitted for API clients using OAuth.' }] }, status: :forbidden }
      end
    end
  end

  def determine_custom_metadata_keys
    keys = []
    root_key = controller_name.singularize.to_sym
    attribute_params = params[root_key][:custom_metadata_attributes]
    if attribute_params && attribute_params[:custom_metadata_type_id].present?
      metadata_type = CustomMetadataType.find(attribute_params[:custom_metadata_type_id])
      if metadata_type
        keys = [:custom_metadata_type_id] + metadata_type.custom_metadata_attributes.collect(&:method_name)
      end
    end
    keys
  end

  # Dynamically get parent resource from URL.
  # i.e. /data_files/123/some_sub_resource/456
  # would fetch DataFile with ID 123
  #
  def get_parent_resource
    parent_id_param = request.path_parameters.keys.detect { |k| k.to_s.end_with?('_id') }
    if parent_id_param
      parent_type = parent_id_param.to_s.chomp('_id')
      parent_class = parent_type.camelize.constantize
      if parent_class
        @parent_resource = parent_class.find(params[parent_id_param])
      end
    end
  end

  def managed_programme_configured?
    unless Programme.managed_programme
      error("No managed #{t('programme')} is configured","No managed #{t('programme')} is configured")
      return false
    end
  end

  # This is a silly method to turn an Array of AR objects back into an AR relation so we can do joins etc. on it.
  def relationify_collection(collection)
    if collection.is_a?(Array)
      controller_model.where(id: collection.map(&:id))
    else
      collection
    end
  end

  def determine_custom_metadata_keys
    keys = []
    root_key = controller_name.singularize.to_sym
    attribute_params = params[root_key][:custom_metadata_attributes]
    if attribute_params && attribute_params[:custom_metadata_type_id].present?
      metadata_type = CustomMetadataType.find(attribute_params[:custom_metadata_type_id])
      if metadata_type
        keys = [:custom_metadata_type_id]
        keys = keys + [{data:[metadata_type.custom_metadata_attributes.collect(&:title)]}]
      end
    end
    keys
  end

  def check_displaying_single_page
    if params[:single_page]
      @single_page = true
    end
  end

  def displaying_single_page?
    @single_page || false
  end

  helper_method :displaying_single_page?

  def display_isa_graph?
    !displaying_single_page?
  end

  helper_method :display_isa_graph?


  def creator_related_params
    [:other_creators,
     # For directly assigning SEEK people (API):
     { creator_ids: [] },
     # For directly setting SEEK and non-SEEK people (API):
     { api_assets_creators: [:creator_id, :given_name,
                             :family_name, :affiliation,
                             :orcid, :pos] },
     # For incrementally adding, removing, modifying  SEEK and non-SEEK people (UI):
     { assets_creators_attributes: [:id, :creator_id, :given_name,
                                    :family_name, :affiliation,
                                    :orcid, :pos, :_destroy] }
    ]
  end
end
