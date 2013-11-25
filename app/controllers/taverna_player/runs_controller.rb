module TavernaPlayer
  class RunsController < TavernaPlayer::ApplicationController
    include TavernaPlayer::Concerns::Controllers::RunsController

    before_filter :auth, :except => [ :index, :new, :create ]
    before_filter :find_runs, :only => :index
    before_filter :add_sweeps, :only => :index
    before_filter :filter_users_runs_and_sweeps, :only => :index
    after_filter :find_workflow_and_version, :only => :new

    def edit
      @run = Run.find(params[:id])
    end

    def update
      @run.attributes = params[:run]

      if params[:sharing]
        @run.policy_or_default
        @run.policy.set_attributes_with_sharing params[:sharing], @run.projects
      end

      if @run.save
        respond_to do |format|
          # Render show.html.erb unless the run is embedded.
          format.html { render "taverna_player/runs/show" }
        end
      else
        puts @run.errors.full_messages
        respond_to do |format|
          format.html { render "taverna_player/runs/edit" }
        end
      end
    end

    # POST /runs
    def create
      @run = Run.new(params[:run])
      @run.policy.set_attributes_with_sharing params[:sharing], @run.projects

      respond_to do |format|
        if @run.save
          format.html { redirect_to @run, :notice => 'Run was successfully created.' }
        else
          format.html { render :action => "new" }
        end
      end
    end

    # GET /runs
    def index
      respond_to do |format|
        format.html # index.html.erb
        format.js # index.js.erb
      end
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

    private

    def find_workflow_and_version
      @workflow = @run.workflow || TavernaPlayer.workflow_proxy.class_name.find(params[:workflow_id])

      unless params[:version].blank?
        @workflow_version = @workflow.find_version(params[:version])
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
      select = params[:workflow_id] ? { :workflow_id => params[:workflow_id] } : {}
      @runs = Run.where(select).includes(:sweep).includes(:workflow).all
      @runs = @runs & Run.all_authorized_for('view', current_user)
    end

    # Overrides the method from TavernaPlayer::Concerns::Controllers::RunsController
    # to check for non-existing runs and failing gracefully instead of throwing 404 Not found.
    def find_run
      if Run.where(:id => params[:id]).blank?
        respond_to do |format|
          flash[:error] = 'The run you are looking for does not exist.'
          format.html { redirect_to runs_path}
        end
      else
        @run = Run.find(params[:id])
      end
    end

    # Returns a list of simple Run objects and Sweep objects
    def add_sweeps
      @runs = @runs.group_by { |run| run.sweep }
      @runs = (@runs[nil] || []) + @runs.keys
      @runs.compact! # to ignore 'nil' key
    end

    def filter_users_runs_and_sweeps
      @user_runs = @runs.select do |run|
        run.is_a?(Sweep) && run.user == current_user ||
        run.is_a?(TavernaPlayer::Run) && run.contributor == current_user
      end

      @runs = @runs - @user_runs
    end

    def auth
      action = translate_action(action_name)
      unless is_auth?(@run, action)
        if User.current_user.nil?
          flash[:error] = "You are not authorized to #{action} this Workflow Run, you may need to login first."
        else
          flash[:error] = "You are not authorized to #{action} this Workflow Run."
        end
        respond_to do |format|
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
  end
end
