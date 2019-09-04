class PeopleController < ApplicationController
  include Seek::IndexPager
  include Seek::AnnotationCommon
  include Seek::Publishing::PublishingCommon
  include Seek::Publishing::GatekeeperPublish
  include Seek::FacetedBrowsing
  include Seek::DestroyHandling
  include Seek::AdminBulkAction
  include RelatedItemsHelper

  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[show edit update destroy items]
  before_action :current_user_exists, only: %i[register create new]
  before_action :is_during_registration, only: [:register]
  before_action :is_user_admin_auth, only: [:destroy]
  before_action :auth_to_create, only: %i[new create]
  before_action :editable_by_user, only: %i[edit update]

  skip_before_action :partially_registered?, only: %i[register create]
  skip_before_action :project_membership_required, only: %i[create new]
  skip_after_action :request_publish_approval, :log_publishing, only: %i[create update]

  cache_sweeper :people_sweeper, only: %i[update create destroy]
  include Seek::BreadCrumbs

  protect_from_forgery only: []

  # GET /people/1
  # GET /people/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.rdf { render template: 'rdf/show' }
      format.xml
      format.json {render json: @person}
    end
  end

  def items
    respond_to do |format|
      format.html
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new
    respond_to do |format|
      format.html { render action: 'new' }
      format.xml  { render xml: @person }
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
    if email && Person.not_registered_with_matching_email(email).any?
      render :is_this_you, locals: { email: email }
    else
      @person = Person.new(email: email)
    end
  end

  # POST /people
  # POST /people.xml
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
          notify_admin_and_project_administrators_of_new_user
        end
        if current_user.active?
          flash[:notice] = 'Person was successfully created.'
          if @person.only_first_admin_person?
            format.html { redirect_to registration_form_admin_path(during_setup: 'true') }
          else
            format.html { redirect_to(@person) }
          end
          format.xml { render xml: @person, status: :created, location: @person }
          format.json {render json: @person, status: :created, location: @person }
        else
          Mailer.signup(current_user).deliver_later
          flash[:notice] = 'An email has been sent to you to confirm your email address. You need to respond to this email before you can login'
          logout_user
          format.html { redirect_to controller: 'users', action: 'activation_required' }
          format.json { render json: @person, status: :created} # There must be more to be done
        end
      else
        format.html { render redirect_action }
        format.xml { render xml: @person.errors, status: :unprocessable_entity }
        format.json { render json: json_api_errors(@person), status: :unprocessable_entity }
      end
    end
  end

  def notify_admin_and_project_administrators_of_new_user
    Mailer.contact_admin_new_user(notification_params.to_h, current_user).deliver_later

    # send mail to project managers
    project_administrators = project_administrators_of_selected_projects params[:projects]
    project_administrators.each do |project_administrator|
      Mailer.contact_project_administrator_new_user(project_administrator, notification_params.to_h, current_user).deliver_later
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person.disciplines.clear if params[:discipline_ids].nil?

    set_tools_and_expertise(@person, params)

    unless @person.notifiee_info.nil?
      @person.notifiee_info.receive_notifications = (params[:receive_notifications] ? true : false)
      @person.notifiee_info.save if @person.notifiee_info.changed?
    end

    respond_to do |format|
      if @person.update_attributes(person_params) && set_group_membership_project_position_ids(@person, params)
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
        format.json {render json: @person}
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @person.errors, status: :unprocessable_entity }
        format.json { render json: json_api_errors(@person), status: :unprocessable_entity }
      end
    end
  end

  def set_group_membership_from_api_params(person,params)
    person.group_memberships.each do |gr|
      #gr.project_positions.clear ???
      params[:person][:project_positions].each do |pos|
        if (gr.project.id.to_s == pos[:project_id].to_s)
          r = ProjectPosition.find(pos[:position_id])
          gr.project_positions << r
        end
      end
    end
  end

  def set_group_membership_project_position_ids(person, params)
    if params[:person][:project_positions].nil?
      prefix = 'group_membership_role_ids_'
      person.group_memberships.each do |gr|
        key = prefix + gr.id.to_s
        gr.project_positions.clear
        next unless params[key.to_sym]
        params[key.to_sym].each do |r|
          r = ProjectPosition.find(r)
          gr.project_positions << r
        end
      end
    else
      set_group_membership_from_api_params(person, params)
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
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
      format.xml { head :ok }
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
      people = workgroup.people
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
    # String concatenation varies across SQL implementations :(
    concat_clause = if Seek::Util.database_type == 'sqlite3'
                      "LOWER(first_name || ' ' || last_name)"
                    else
                      "LOWER(CONCAT(first_name, ' ', last_name))"
                    end

    results = Person.where("#{concat_clause} LIKE :query OR LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query",
                           query: "#{params[:query].downcase}%").limit(params[:limit] || 10)
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
    params.permit(:projects, :institutions, :other_projects, :other_institutions)
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

  def set_project_related_roles(person)
    return unless params[:roles]

    administered_project_ids = Project.all_can_be_administered.collect { |p| p.id.to_s }

    Seek::Roles::ProjectRelatedRoles.role_names.each do |role_name|
      # remove for the project ids that can be administered
      person.remove_roles(Seek::Roles::RoleInfo.new(role_name: role_name, items: administered_project_ids))

      # add only the project ids that can be administered
      if project_ids = (params[:roles][role_name] & administered_project_ids)
        person.add_roles(Seek::Roles::RoleInfo.new(role_name: role_name, items: project_ids))
      end
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
    unless @person.can_be_edited_by?(current_user)
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

  def find_assets
    @people = nil
    if params[:discipline_id]
      @discipline = Discipline.find_by_id(params[:discipline_id])
      @people = @discipline.try(:people) || []
    elsif params[:project_position_id]
      @project_position = ProjectPosition.find(params[:project_position_id])
      @people = Person.includes(:group_memberships)
      # FIXME: this needs double checking, (a) not sure its right, (b) can be paged when using find.
      @people = @people.reject { |p| (p.group_memberships & @project_position.group_memberships).empty? }
    end

    super unless @people

    @people = @people.select(&:can_view?)
  end
end
