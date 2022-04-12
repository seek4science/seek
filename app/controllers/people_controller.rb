class PeopleController < ApplicationController
  include Seek::IndexPager
  include Seek::AnnotationCommon
  include Seek::Publishing::PublishingCommon
  include Seek::Sharing::SharingCommon
  include Seek::Publishing::GatekeeperPublish
  include Seek::DestroyHandling
  include Seek::AdminBulkAction
  include RelatedItemsHelper

  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[show edit update destroy items batch_sharing_permission_preview]
  before_action :current_user_exists, only: %i[register create new]
  before_action :is_during_registration, only: [:register]
  before_action :is_user_admin_auth, only: [:destroy]
  before_action :auth_to_create, only: %i[new create]
  before_action :editable_by_user, only: %i[edit update]

  skip_before_action :partially_registered?, only: %i[register create]
  skip_before_action :project_membership_required, only: %i[create new]
  skip_after_action :request_publish_approval, :log_publishing, only: %i[create update]

  cache_sweeper :people_sweeper, only: %i[update create destroy]

  protect_from_forgery only: []

  api_actions :index, :show, :create, :update, :destroy, :current

  # GET /people/1
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.rdf { render template: 'rdf/show' }
      format.json {render json: @person, include: [params[:include]]}
    end
  end

  def items
    respond_to do |format|
      format.html
    end
  end

  def current
    respond_to do |format|
      format.json do
        if logged_in?
          render json: current_user.person
        else
          render json: { errors: [{ title: 'No user logged in'}] }, status: :not_found
        end
      end
    end
  end

  # GET /people/new
  def new
    @person = Person.new
    respond_to do |format|
      format.html { render action: 'new' }
    end
  end

  # GET /people/1/edit
  def edit
    possible_unsaved_data = "unsaved_#{@person.class.name}_#{@person.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and regular users won't (and MUST NOT)
        # be able to use these; admins on the other hand are most likely to never change
        # any avatars - therefore, it's better to hide these attributes so they never get
        # updated from the session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for person's work group memberships would already be created, which is an
        # error (if the following 3 lines are ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:person].delete(:work_group_ids)

        # update those attributes of a person that we want to be updated from the session
        @person.attributes = session[possible_unsaved_data][:person]
      end

      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # GET /people/select
  #
  # Page for after registration that allows you to select yourself from a list of
  # people yet to be assigned, or create a new one if you don't exist
  def register
    email = params[:email]
    @existing_email = email && Person.where(email: email).any?
    if email && Person.not_registered_with_matching_email(email).any?
      render :is_this_you, locals: { email: email }
    else
      p = { email: email }
      p[:first_name], p[:last_name] = params[:name].split(' ') if params[:name].present?
      p[:first_name] = params[:first_name] if params[:first_name]
      p[:last_name] = params[:last_name] if params[:last_name]
      @person = Person.new(p)
    end
  end

  # POST /people
  def create
    @person = Person.new(person_params)

    redirect_action = 'new'

    unless current_user.registration_complete?
      current_user.person = @person
      redirect_action = 'register'
      during_registration = true
    end
    set_tools_and_expertise(@person, params)
    respond_to do |format|
      if @person.save && current_user.save
        if Seek::Config.email_enabled && during_registration
          Mailer.contact_admin_new_user(current_user).deliver_later
        end
        if current_user.active?
          flash[:notice] = 'Person was successfully created.'
          if @person.only_first_admin_person?
            format.html { redirect_to registration_form_admin_path(during_setup: 'true') }
          else
            if Seek::Config.programmes_enabled && Programme.site_managed_programme
              format.html { redirect_to(create_or_join_project_home_path)}
            else
              format.html { redirect_to(@person) }
            end

          end
          format.json {render json: @person, status: :created, location: @person, include: [params[:include]] }
        else
          Mailer.activation_request(current_user).deliver_later
          ActivationEmailMessageLog.log_activation_email(@person)
          flash[:notice] = 'An email has been sent to you to confirm your email address. You need to respond to this email before you can login'
          logout_user
          format.html { redirect_to controller: 'users', action: 'activation_required' }
          format.json { render json: @person, status: :created, include: [params[:include]]} # There must be more to be done
        end
      else
        format.html { render redirect_action }
        format.json { render json: json_api_errors(@person), status: :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  def update
    @person.disciplines.clear if params[:discipline_ids].nil? #????

    set_tools_and_expertise(@person, params)

    unless @person.notifiee_info.nil?
      @person.notifiee_info.receive_notifications = (params[:receive_notifications] ? true : false)
      @person.notifiee_info.save if @person.notifiee_info.changed?
    end

    respond_to do |format|
      if @person.update(person_params)
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.json {render json: @person, include: [params[:include]]}
      else
        format.html { render action: 'edit' }
        format.json { render json: json_api_errors(@person), status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  def destroy
    @person.destroy

    respond_to do |format|
      if request.env['HTTP_REFERER'].try(:include?, '/admin')
        format.html { redirect_to(admin_url) }
        format.json {render json: {status: :ok}, status: :ok}
      else
        format.html { redirect_to(people_url) }
        format.json {render json: {status: :ok}, status: :ok}
      end
    end
  end

  def get_work_group
    people = nil
    project_id = params[:project_id]
    institution_id = params[:institution_id]
    if institution_id == '0'
      project = Project.find(project_id)
      people = project.people
    else
      workgroup = WorkGroup.find_by_project_id_and_institution_id(project_id, institution_id)
      people = workgroup ? workgroup.people : []
    end
    people_list = people.collect { |p| [h(p.name), p.email, p.id] }
    respond_to do |format|
      format.json do
        render json: { status: 200, people_list: people_list }
      end
    end
  end

  # For use in autocompleters
  def typeahead
    results = Person.with_name(params[:query]).limit(params[:limit] || 10)

    items = results.map do |person|
      { id: person.id, name: person.name, projects: person.projects.collect(&:title).join(', '), hint: person.typeahead_hint }
    end

    respond_to do |format|
      format.json { render json: items.to_json }
    end
  end

  private

  def person_params
    params.require(:person).permit(:first_name, :last_name, :orcid, :description, :email, :web_page, :phone,
                                   :skype_name, { discipline_ids: [] }, { expertise: [] }, { tools: [] },
                                   project_subscriptions_attributes: %i[id project_id _destroy frequency])
  end

  def administer_person_params
    if params[:person] && User.admin_or_project_administrator_logged_in?
      params.require(:person).permit(work_group_ids: [])
    else
      {}
    end
  end

  # Unused...
  def role_params
    params.require(:roles).permit({ pal: [] }, { project_administrator: [] }, { asset_housekeeper: [] }, asset_gatekeeper: [])
  end

  def notification_params
    params.permit({ projects: [] }, { institutions: [] }, :other_projects, :other_institutions)
  end

  def set_tools_and_expertise(person, params)
    exp_changed = person.add_annotations(params[:expertise_list], 'expertise') if params[:expertise_list]
    tools_changed = person.add_annotations(params[:tool_list], 'tool') if params[:tool_list]
    if immediately_clear_tag_cloud?
      expire_annotation_fragments('expertise') if exp_changed
      expire_annotation_fragments('tool') if tools_changed
    else
      RebuildTagCloudsJob.new.queue_job
    end
  end

  def is_user_admin_or_personless
    unless User.admin_logged_in? || !current_user.registration_complete?
      error('You do not have permission to create new people', 'Is invalid (not admin)')
      false
    end
  end

  def current_user_exists
    redirect_to(:root) unless current_user
    !!current_user
  end

  def project_administrators_of_selected_projects(project_ids)
    if project_ids.blank?
      []
    else
      Project.where(id: project_ids).collect(&:project_administrators).flatten.uniq
    end
  end

  def editable_by_user
    unless @person.can_edit?(current_user)
      error('Insufficient privileges', 'is invalid (insufficient_privileges)')
      false
    end
  end

  def is_during_registration
    if User.logged_in_and_registered?
      error('You cannot register a new profile to yourself as you are already registered', 'Is invalid (already registered)')
      false
    end
  end
end
