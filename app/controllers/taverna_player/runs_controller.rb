module TavernaPlayer
  class RunsController < TavernaPlayer::ApplicationController
    include TavernaPlayer::Concerns::Controllers::RunsController

    before_filter :find_workflow_and_version, :only => :new
    before_filter :set_user, :only => :create

    def new
      @run = Run.new
      @run.embedded = true if params[:embedded] == "true"

      respond_to do |format|
        # Render new.html.erb unless the run is embedded.
        format.html { render "taverna_player/runs/embedded/new" if @run.embedded }
      end
    end

    def update
      new_name = params[:run_name]

      # Name cannot be blank - show the erro message to the user
      if new_name.blank?
        flash[:error] = 'Run name cannot be blank.'
        flash[:notice] = nil
      # If the new name is the same as the current run name - do nothing
      elsif new_name != @run.name
        @run.name = new_name
        @run.save!
        flash[:notice] = 'Run name updated.'
        flash[:error] = nil
      end

      respond_to do |format|
        # Render show.html.erb unless the run is embedded.
        format.html { render "taverna_player/runs/show" }
      end
    end

    private

    def find_workflow_and_version
      @workflow = TavernaPlayer.workflow_proxy.class_name.find(params[:workflow_id])

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

    def set_user
      #params[:run][:user_id] = current_user.id
    end
  end
end
