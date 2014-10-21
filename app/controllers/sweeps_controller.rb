class SweepsController < ApplicationController

  before_filter :workflows_enabled?

  skip_before_filter :restrict_guest_user, :only => :new
  skip_after_filter :log_event, :only => :runs

  before_filter :find_sweep, :except => [:create, :new, :index]
  before_filter :find_run, :only => :new
  before_filter :set_runlet_parameters, :only => :create
  before_filter :find_workflow_and_version, :only => :new
  before_filter :auth, :except => [ :index, :new, :create ]

  def show
    @runs = @sweep.runs.select { |r| r.can_view? }
  end

  def new
    @sweep = Sweep.new
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @sweep.attributes = params[:sweep]

    if params[:sharing]
      @sweep.policy_or_default
      @sweep.policy.set_attributes_with_sharing params[:sharing], @sweep.projects
    end

    if @sweep.save
      respond_to do |format|
        format.html { redirect_to sweep_path(@sweep) }
      end
    else
      respond_to do |format|
        format.html { render edit_sweep_path(@sweep) }
      end
    end
  end

  def create

    @sweep = Sweep.new(params[:sweep])
    @workflow = @sweep.workflow
    @workflow_version = @workflow.find_version(@sweep.workflow_version)

    raise if @workflow.nil?
    # Manually add projects of current user, as they aren't prompted for this information in the form
    @sweep.projects = current_user.person.projects
    @sweep.policy.set_attributes_with_sharing params[:sharing], @sweep.projects
    respond_to do |format|
      if @sweep.save
        format.html { redirect_to sweep_path(@sweep) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def cancel
    @sweep.cancel
    respond_to do |format|
      format.html { redirect_to taverna_player.runs_path }
    end
  end

  def destroy
    @sweep.destroy
    respond_to do |format|
      format.html { redirect_to params[:redirect_to].blank? ? taverna_player.runs_path : params[:redirect_to]}
    end
  end

  def runs
    @sweep = Sweep.find(params[:id], :include => {:runs => :workflow})
    @runs = @sweep.runs.select { |r| r.can_view? }
    respond_to do |format|
      format.js { render "taverna_player/runs/index" }
    end
  end

  # Display the result value for a given output port of a given run.
  def view_result
    respond_to do |format|
      format.js  { render 'view_result.js.erb' }
    end
  end

  # Zip/assemble results for a given output port over selected sweep's runs,
  # results for a run (for all output ports), or all results for all output ports
  # and all runs.
  def download_results
    @sweep = Sweep.find(params[:id], :include => { :runs => :outputs })

    if params[:download].blank?
      respond_to do |format|
        flash[:error] = "You must select at least one output to download"
        format.html { redirect_to :back }
      end
    else
      outputs = []
      params[:download].each do |run_id, output_names|
        outputs = outputs + @sweep.runs.detect {|r| r.id == run_id.to_i}.outputs.select {|o| output_names.include?(o.name)}
      end

      path = @sweep.build_zip(outputs)

      respond_to do |format|
        format.html {send_file path, :type => "application/zip",
          :filename => path.split('/').last }
      end
    end
  end

  private

  def find_run
    if !params[:run_id].blank? # New sweep based on a previous special_run
      @run = TavernaPlayer::Run.find(params[:run_id], :include => :inputs)
    else # New sweep from scratch
      @run = nil
    end
  end

  def find_workflow_and_version
    if !@run.blank?
      @workflow = @run.workflow
      @workflow_version = @run.executed_workflow
    else
      @workflow = Workflow.find(params[:workflow_id])
      @workflow_version = params[:version].blank? ? @workflow.latest_version : @workflow.find_version(params[:version])
    end
  end

  def set_runlet_parameters

    shared_input_values_for_all_runs = params[:sweep].delete(:shared_input_values_for_all_runs)
    params[:sweep][:runs_attributes].each_with_index do |(run_id, run_attributes), iteration_index|
      run_attributes[:workflow_id] = params[:sweep][:workflow_id]
      run_attributes[:workflow_version] = params[:sweep][:workflow_version]

      # Set parent ID to replay interactions
      run_attributes[:parent_id] = params[:run_id].to_i unless params[:run_id].blank?
      run_attributes[:project_ids] = current_user.person.projects.map { |p| p.id }

      # Copy shared inputs from "parent" run
      if !shared_input_values_for_all_runs.blank?
        base_index = run_attributes[:inputs_attributes].keys.map { |k| k.to_i }.max + 1
        if shared_input_values_for_all_runs[:inputs_attributes]
          shared_input_values_for_all_runs[:inputs_attributes].each do |input_id, input_attributes|
            run_attributes[:inputs_attributes][(base_index + input_id.to_i).to_s] = input_attributes
          end
        end
      end

      # Set the runlet names based on their input data, or just number them
      unless params[:name_input].blank?
        i = run_attributes[:inputs_attributes].values.detect {|v| v[:name] == params[:name_input]}
        if i[:file]
          identifier = "#{i[:file].original_filename}"
        elsif !i[:value].blank?
          identifier = "#{i[:value][0...32]}"
          identifier << '...' if i[:value].length > 32
        end
      end
      identifier ||= "(#{iteration_index + 1})"
      run_attributes[:name] = "#{params[:sweep][:name]} - #{identifier}"

      # Set the project for each runlet
      run_attributes[:project_ids] = current_user.person.projects.map { |p| p.id }
    end
  end

  def auth
    action = translate_action(action_name)
    unless is_auth?(@sweep, action)
      if User.current_user.nil?
        flash[:error] = "You are not authorized to #{action} this Sweep, you may need to login first."
      else
        flash[:error] = "You are not authorized to #{action} this Sweep."
      end
      respond_to do |format|
        format.html do
          case action
            when 'manage','edit','download','delete'
              redirect_to @sweep
            else
              redirect_to taverna_player.runs_path
          end
        end
      end
    end
  end

  def find_sweep
    @sweep = Sweep.find(params[:id], :include => :runs)
  end

end
