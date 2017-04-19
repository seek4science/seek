module TavernaPlayer
  class RunsController < TavernaPlayer::ApplicationController
    include TavernaPlayer::Concerns::Controllers::RunsController
    include Seek::AssetsStandardControllerActions

    before_filter :workflows_enabled?

    skip_before_filter :project_membership_required
    skip_before_filter :restrict_guest_user, :only => :new
    skip_after_filter :log_event, :only => :show, :if => proc {|_| request.xhr?}

    before_filter :check_project_membership_unless_embedded, :only => [:create, :new]
    before_filter :auth, :except => [ :index, :new, :create ]
    before_filter :add_sweeps, :only => :index
    before_filter :find_workflow_and_version, :only => :new
    before_filter :auth_workflow, :only => :new

    def update
      @run.update_attributes(params[:run])

      update_sharing_policies @run

      respond_with(@run)
    end

    # POST /runs
    def create
      @run = Run.new(params[:run])
      # Need to set workflow and workflow_version incase the create fails and redirects to 'new'
      @workflow = @run.workflow
      @workflow_version = @run.executed_workflow
      auth_workflow
      # Manually add projects of current user, as they aren't prompted for this information in the form
      @run.projects = @run.contributor.person.projects
      @run.policy.set_attributes_with_sharing(params[:policy_attributes])

      if @run.save
        flash[:notice] = "Run was successfully created."
      end

      respond_with(@run, :status => :created, :location => @run)
    end

    # DELETE /runs/1
    def destroy
      if @run.destroy
        flash[:notice] = "Run was deleted."
        respond_with(@run) do |format|
          format.html { redirect_to params[:redirect_to].blank? ? :back : params[:redirect_to]}
        end
      else
        flash[:error] = "Run must be cancelled before deletion."
        respond_with(@run, :nothing => true, :status => :forbidden) do |format|
          format.html { redirect_to :back}
        end
      end
    end

    def report_problem
      if @run.reported?
        flash[:error] = "This run has already been reported."
        respond_with(@run, :status => 400)
      elsif !@run.reportable?
        flash[:error] = "This run contains no errors."
        respond_with(@run, :status => 400)
      else
        if Seek::Config.email_enabled
          Mailer.report_run_problem(current_person, @run).deliver_now
          @run.reported = true
          @run.save
          flash[:notice] = "Your report has been submitted to the support team, thank you."
        end
        respond_with(@run)
      end
    end

    private

    def find_workflow_and_version
      @workflow = @run.workflow || TavernaPlayer.workflow_proxy.class_name.find(params[:workflow_id])
      @workflow_version = params[:version].blank? ? @workflow.latest_version : @workflow.find_version(params[:version])
    end

    def auth_workflow
      unless @workflow.can_perform?("view")
        flash[:error] = "You are not authorized to run this workflow."
        respond_to do |format|
          format.html { redirect_to main_app.workflows_path }
        end
      end
    end

    def choose_layout
      if (action_name == "new" || action_name == "show") && @run.embedded?
       "taverna_player/embedded"
      else
        ApplicationController.new.send(:_layout)
      end
    end

    def find_runs
      @runs = Run.where(:embedded => :false).
          includes(:sweep => [:workflow, :policy, :contributor]).
          includes(:workflow => [:policy, :contributor, :category]).
          includes(:policy)

      @runs = @runs.where(:workflow_id => params[:workflow_id]) if params[:workflow_id]

      if request.format.to_s.include?("json")
        @runs = Run.authorize_asset_collection(@runs.all, 'view', current_user)
      else
        @user_runs  = @runs.where(:contributor_id => current_user, :contributor_type => 'User').all # Don't need to auth, because contributor can always view!
        @extra_runs = @runs.where("contributor_id != ? AND contributor_type = 'User'", current_user).order('created_at DESC')
        unless params[:no_limit]
          @extra_runs = @extra_runs.limit(75)
        end

        @extra_runs = Run.authorize_asset_collection(@extra_runs.all, 'view', current_user)

        @runs = @user_runs + @extra_runs
      end
    end

    # Overrides the method from TavernaPlayer::Concerns::Controllers::RunsController
    # to check for non-existing runs and failing gracefully instead of throwing 404 Not found.
    def find_run
      if Run.where(:id => params[:id]).blank?
        respond_to do |format|
          flash[:error] = 'The run you are looking for does not exist.'
          format.html { redirect_to runs_path }
          format.json { render :nothing => true, :status => "404" }
        end
      else
        @run = Run.find(params[:id])
      end
    end

    # Returns a list of simple Run objects and Sweep objects. We do not want
    # to group sweeps when serving json, though. There may be a better way...
    def add_sweeps
      return if request.format.to_s.include?("json")
      @extra_runs, @user_runs = [@extra_runs, @user_runs].map do |coll|
        coll = coll.group_by { |run| run.sweep } # Create a hash of Sweep => [Runs]
        coll = (coll[nil] || []) + coll.keys # Get an array of all the runs without sweeps, and then all the sweeps
        coll.compact # to ignore 'nil' key
      end
    end

    def auth
      # Skip certain auth if run is embedded
      if @run.embedded
        if ['cancel','read_interaction','write_interaction'].include?(action_name)
          return true
        end
      end

      action = translate_action(action_name)
      unless is_auth?(@run, action)
        if current_user.nil?
          flash[:error] = "You are not authorized to #{action} this Workflow Run, you may need to login first."
        else
          flash[:error] = "You are not authorized to #{action} this Workflow Run."
        end
        respond_with(@run, :nothing => true, :status => :unauthorized) do |format|
          format.html do
            case action
              when 'manage','edit','download','delete'
                redirect_to @run
              else
                redirect_to taverna_player.runs_path
            end
          end
        end
      end
    end

    def check_project_membership_unless_embedded
      unless (params[:run] && params[:run][:embedded] == 'true') || (params[:embedded] && params[:embedded] == 'true')
        project_membership_required
      end
    end

  end
end
