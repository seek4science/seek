	# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  skip_after_filter :add_piwik_analytics_tracking if Seek::Config.piwik_analytics_enabled == false

  self.mod_porter_secret = PORTER_SECRET

  include ExceptionNotifiable
  self.error_layout="errors"
  self.silent_exceptions = []
  self.rails_error_classes = {
  ActiveRecord::RecordNotFound => "404",
  ::ActionController::UnknownController => "406",
  ::ActionController::UnknownAction => "406",
  ::ActionController::RoutingError => "404",  
  ::ActionView::MissingTemplate => "406",
  ::ActionView::TemplateError => "500"
  }
  local_addresses.clear

  exception_data :additional_exception_notifier_data

  after_filter :log_event

  include AuthenticatedSystem
  around_filter :with_current_user
  def with_current_user
    User.with_current_user current_user do
      yield
    end
  end

  before_filter :project_membership_required,:only=>[:create,:new]

  helper :all

  layout "main"

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'cfb59feef722633aaee5ee0fd816b5fb'

  def set_no_layout
    self.class.layout nil
  end

  def base_host
    request.host_with_port
  end


  def self.fast_auto_complete_for(object, method, options = {})
    define_method("auto_complete_for_#{object}_#{method}") do
      render :json => object.to_s.camelize.constantize.find(:all).map(&method).to_json
    end
  end

  #Overridden from restful_authentication
  #Does a second check that there is a profile assigned to the user, and if not goes to the profile
  #selection page (GET people/select)
  def authorized?
    if super
      redirect_to(select_people_path) if current_user.person.nil?
      true
    else
      false
    end
  end

  def is_user_activated
    if Seek::Config.activation_required_enabled && current_user && !current_user.active?
      error("Activation of this account it required for gaining full access", "Activation required?")
      false
    end
  end

  def is_current_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
      return false
    end

    unless @user
      error("User not found (or not authorized)", "is invalid (not owner)")
      return false
    end
  end

  def is_user_admin_auth
    unless User.admin_logged_in?
      error("Admin rights required", "is invalid (not admin)")
      return false
    end
    return true
  end

  def can_manage_announcements?
    User.admin_logged_in?
  end

  def logout_user
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    cookies.delete :open_id
    reset_session
  end

  def find_or_create_substance(new_substances, known_substance_ids_and_types)
    known_substances = []
    known_substance_ids_and_types.each do |text|
      id, type = text.split(',')
      id = id.strip
      type = type.strip.capitalize.constantize
      known_substances.push(type.find(id)) if type.find(id)
    end
    new_substances, known_substances = check_if_new_substances_are_known new_substances, known_substances
    #no substance
    if (new_substances.size + known_substances.size) == 0
      nil
    #one substance
    elsif (new_substances.size + known_substances.size) == 1
      if !known_substances.empty?
        known_substances.first
      else
        c = Compound.new(:name => new_substances.first)
          if  c.save
            c
          else
            nil
          end
      end
    #FIXME: update code when mixture table is created
    else
      nil
    end
  end

  def no_comma_for_decimal
    check_string = ''
    if self.controller_name.downcase == 'studied_factors'
      check_string.concat(params[:studied_factor][:start_value].to_s + params[:studied_factor][:end_value].to_s + params[:studied_factor][:standard_deviation].to_s)
    elsif self.controller_name.downcase == 'experimental_conditions'
      check_string.concat(params[:experimental_condition][:start_value].to_s + params[:experimental_condition][:end_value].to_s)
    end

    if check_string.match(',')
         render :update do |page|
           page.alert('Please use point instead of comma for decimal number')
         end
      return false
    else
      return true
    end
  end
  private

  def project_membership_required
    unless try_block {current_user.person.member? or User.admin_logged_in?}
      flash[:error] = "Only members of known projects, institutions or work groups are allowed to create new content."
      respond_to do |format|
        format.html do
          try_block {redirect_to eval("#{controller_name}_path")} or redirect_to root_url
        end
        format.json { render :json => {:status => 401, :error_message => flash[:error] } }
      end

    end

  end

  def pal_or_admin_required
    unless User.admin_logged_in? || (User.pal_logged_in?)
      error("Admin or PAL rights required", "is invalid (not admin)")
      return false
    end
  end

  #used to suppress elements that are for virtualliver only or are still currently being worked on
  def virtualliver_only
    if !Seek::Config.is_virtualliver
      error("This feature is is not yet currently available","invalid route")
      return false
    end
  end

  def check_allowed_to_manage_types
    unless Seek::Config.type_managers_enabled
      error("Type management disabled", "...")
      return false
    end

    if User.current_user.can_manage_types?
      return true
    else
      case Seek::Config.type_managers
        when "admins"
          error("Admin rights required to manage types", "...")
          return false

        when "pals"
          error("Admin or PAL rights required to manage types", "...")
          return false

        when "none"
          error("Type management disabled", "...")
          return false
      end
    end
  end

  def currently_logged_in
    current_user.person
  end

  def error(notice, message)
    flash[:error] = notice
     (err = User.new.errors).add(:id, message)

    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

  #The default for the number items in a page when paginating
  def default_items_per_page
    7
  end

  #required for the Savage Beast
  def admin?
    User.admin_logged_in?
  end

  def email_enabled?
    Seek::Config.email_enabled
  end

  def translate_action action_name
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete',
          'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate',
          'tag', 'items', 'statistics', 'tag_suggestions', 'preview'
        'view'

      when 'download', 'named_download', 'launch', 'submit_job', 'data', 'execute','plot'
        'download'

      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version',
          'destroy_version', 'edit_version', 'update_version', 'new_item',
          'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
        'edit'

      when 'destroy', 'destroy_item'
        'delete'

      when 'manage','preview_publish','publish'
        'manage'

      else
        nil
    end
  end

  def find_and_auth
    begin
      name = self.controller_name.singularize
      action = translate_action(action_name)

      return if action.nil?

      object = name.camelize.constantize.find(params[:id])

      if object.can_perform? action
        eval "@#{name} = object"
        params.delete :sharing unless object.can_manage?(current_user)
      else
        respond_to do |format|
          #TODO: can_*? methods should report _why_ you can't do what you want. Perhaps something similar to how active_record_object.save stores 'why' in active_record_object.errors
          flash[:error] = "You may not #{action} #{name}:#{params[:id]}"
          format.html do
            case action
              when 'manage'   then redirect_to object
              when 'edit'     then redirect_to object
              when 'download' then redirect_to object
              else                 redirect_to eval "#{self.controller_name}_path"
            end
          end
          format.xml { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
          format.json { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the #{name.humanize} or you are not authorized to view it"
        format.html { redirect_to eval "#{self.controller_name}_path" }
      end
      return false
    end
  end

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  def log_event
    User.with_current_user current_user do
      c = self.controller_name.downcase
      a = self.action_name.downcase

      object = eval("@"+c.singularize)

      object=current_user if c=="sessions" #logging in and out is a special case

      #don't log if the object is not valid or has not been saved, as this will a validation error on update or create
      return if object.nil? || (object.respond_to?("new_record?") && object.new_record?) || (object.respond_to?("errors") && !object.errors.empty?)

      case c
        when "sessions"
        if ["create","destroy"].include?(a)
          ActivityLog.create(:action => a,
                     :culprit => current_user,
                     :controller_name=>c,
                     :activity_loggable => object)
        end
        when "investigations","studies","assays","specimens","samples"
        if ["show","create","update","destroy"].include?(a)
          ActivityLog.create(:action => a,
                     :culprit => current_user,
                     :referenced => object.projects.first,
                     :controller_name=>c,
                     :activity_loggable => object,
                      :data=> object.title)

        end
        when "data_files","models","sops","publications","presentations","events"
          a = "create" if a == "upload_for_tool"
          a = "update" if a == "new_version"
        if ["show","create","update","destroy","download"].include?(a)
          ActivityLog.create(:action => a,
                     :culprit => current_user,
                     :referenced => object.projects.first,
                     :controller_name=>c,
                     :activity_loggable => object,
                      :data=> object.title)
        end
        when "people"
        if ["show","create","update","destroy"].include?(a)
          ActivityLog.create(:action => a,
                     :culprit => current_user,
                     :controller_name=>c,
                     :activity_loggable => object,
                      :data=> object.title)
        end
        when "search"
        if a=="index"
          ActivityLog.create(:action => "index",
                     :culprit => current_user,
                     :controller_name=>c,
                     :data => {:search_query=>object,:result_count=>@results.count})
        end
      end
    end
  end

  def permitted_filters
    #placed this in a seperate method so that other controllers could override it if necessary
    Seek::Util.persistent_classes.select {|c| c.respond_to? :find_by_id}.map {|c| c.name.underscore}
  end

  def apply_filters(resources)
    filters = params[:filter] || {}
    #apply_filters will be dispatching to methods based on the symbols in params[:filter].
    #Permitted filters protects us from shennanigans like params[:filter] => {:destroy => 'This will destroy your data'}
    filters.delete_if {|k,v| not (permitted_filters.include? k.to_s) }
    resources.select do |res|
      filters.all? do |filter, value|
        filter = filter.to_s
        klass = filter.camelize.constantize
        value = klass.find_by_id value.to_i

        case
        #first the special cases
        when (filter == 'investigation' and res.respond_to? :assays) then res.assays.collect{|a| a.study.investigation_id}.include? value.id
        when (filter == 'study' and res.respond_to? :assays) then res.assays.collect{|a| a.study_id}.include? value.id
        when (filter == 'person' and res.class.is_asset?)    then (res.creators.include?(value) or res.contributor.try(:person) == value)
        when (filter == 'person' and res.respond_to? :owner) then res.send(:owner) == value
        #then the general case
        when res.respond_to?(filter)                         then res.send(filter) == value
        when res.respond_to?(filter.pluralize)               then res.send(filter.pluralize).include? value
        #defaults to true, if a filter is irrelevant then it is silently ignored
        else true
        end
      end
    end
  end

  def additional_exception_notifier_data
    {
        :current_logged_in_user=>current_user
    }
  end

  #double checks and resolves if any new compounds are actually known. This can occur when the compound has been typed completely rather than
  #relying on autocomplete. If not fixed, this could have an impact on preserving compound ownership.
  def check_if_new_substances_are_known new_substances, known_substances
    fixed_new_substances = []
    new_substances.each do |new_substance|
      substance=Compound.find_by_name(new_substance.strip) || Synonym.find_by_name(new_substance.strip)
      if substance.nil?
        fixed_new_substances << new_substance
      else
        known_substances << substance unless known_substances.include?(substance)
      end
    end
    return fixed_new_substances, known_substances
  end
end
