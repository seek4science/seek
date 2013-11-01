class SweepsController < ApplicationController

  before_filter :find_sweep, :except => [:create, :new, :index, :download_results]
  before_filter :find_run, :only => :new
  before_filter :set_runlet_parameters, :only => :create
  before_filter :find_workflow_and_version, :only => :new
  before_filter :auth, :only => [:update, :edit, :destroy, :cancel]

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
    if @sweep.update_attributes(params[:sweep])
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
    params[:sweep][:user_id] = current_user.id
    @sweep = Sweep.new(params[:sweep])
    @workflow = @sweep.workflow
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
      @workflow = Workflow.find(@run.workflow_id)
    else
      @workflow = Workflow.find(params[:workflow_id])
    end

    unless params[:version].blank?
      @workflow_version = @workflow.find_version(params[:version])
    end
  end

  def set_runlet_parameters

    shared_input_values_for_all_runs = params[:sweep].delete(:shared_input_values_for_all_runs)
    params[:sweep][:runs_attributes].each do |run_id, run_attributes|
      run_attributes[:workflow_id] = params[:sweep][:workflow_id]
      run_attributes[:name] = "#{params[:sweep][:name]} ##{run_id.to_i + 1}"
      # Copy parameters from "parent" run
      if !shared_input_values_for_all_runs.blank?
        base_index = run_attributes[:inputs_attributes].keys.map { |k| k.to_i }.max + 1
        if shared_input_values_for_all_runs && shared_input_values_for_all_runs[:inputs_attributes]
          shared_input_values_for_all_runs[:inputs_attributes].each do |input_id, input_attributes|
            run_attributes[:inputs_attributes][(base_index + input_id.to_i).to_s] = input_attributes
          end
        end
      end
    end
  end

  def auth
    unless @sweep.user == current_user
      respond_to do |format|
        flash[:error] = "You are not authorized to #{action_name} this sweep."
        format.html { redirect_to @sweep }
      end
    end
  end

  def find_sweep
    @sweep = Sweep.find(params[:id], :include => :runs)
  end

end
