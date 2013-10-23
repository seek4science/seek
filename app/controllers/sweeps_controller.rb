class SweepsController < ApplicationController

  before_filter :find_run, :only => :new
  before_filter :find_workflow_and_version, :only => :new
  before_filter :set_runlet_parameters, :only => :create

  def show
    @sweep = Sweep.find(params[:id], :include => :runs)
  end

  def new
    @sweep = Sweep.new
  end

  def create
    params[:sweep][:user_id] = current_user.id
    @sweep = Sweep.new(params[:sweep])
    unless @sweep.save
      puts @sweep.errors.full_messages.inspect
      raise
    end
    respond_to do |format|
      format.html { redirect_to sweep_path(@sweep) }
    end
  end

  def cancel
    @sweep = Sweep.find(params[:id])
    @sweep.cancel
    respond_to do |format|
      format.html { redirect_to taverna_player.runs_path }
    end
  end

  def destroy
    @sweep = Sweep.find(params[:id])
    @sweep.destroy
    respond_to do |format|
      format.html { redirect_to taverna_player.runs_path }
    end
  end

  def runs
    @sweep = Sweep.find(params[:id], :include => {:runs => :workflow})
    @runs = @sweep.runs
    respond_to do |format|
      format.js { render "taverna_player/runs/index" }
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

end
