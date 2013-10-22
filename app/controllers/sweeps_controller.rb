class SweepsController < ApplicationController

  before_filter :find_run, :only => :new
  before_filter :find_workflow_and_version, :only => :new
  before_filter :set_runlet_parameters, :only => :create

  def show
    @sweep = Sweep.find(params[:id])
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
      format.html { redirect_to taverna_player.runs_path(:sweep_id => @sweep.id) }
    end
  end

  def cancel
    @sweep = Sweep.find(params[:id])
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

  private

  def find_run
    if !params[:run_id].blank? # New sweep based on a previous run
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
    params[:sweep][:runs_attributes].each do |run_id, run_attributes|
      run_attributes[:workflow_id] = params[:sweep][:workflow_id]
      run_attributes[:name] = "#{params[:sweep][:name]} ##{run_id.to_i + 1}"
      # Copy parameters from "parent" run
      if !params[:sweep][:run].blank?
        run = params[:sweep].delete(:run)
        base_index = run_attributes[:inputs_attributes].keys.map { |k| k.to_i }.max + 1
        if run && run[:inputs_attributes]
          run[:inputs_attributes].each do |input_id, input_attributes|
            run_attributes[:inputs_attributes][(base_index + input_id.to_i).to_s] = input_attributes
          end
        end
      end
    end
  end

end
