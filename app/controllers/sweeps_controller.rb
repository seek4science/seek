class SweepsController < ApplicationController

  before_filter :find_run, :only => :new
  before_filter :find_workflow_and_version, :only => :new
  before_filter :set_runlet_parameters, :only => :create

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
    @run = TavernaPlayer::Run.find(params[:run_id], :include => :inputs)
  end

  def find_workflow_and_version
    @workflow = Workflow.find(@run.workflow_id)

    unless params[:version].blank?
      @workflow_version = @workflow.find_version(params[:version])
    end
  end

  def set_runlet_parameters
    run = params[:sweep].delete(:run)
    params[:sweep][:runs_attributes].each do |run_id, run_attributes|
      run_attributes[:workflow_id] = params[:sweep][:workflow_id]
      run_attributes[:user_id] = current_user.id
      run_attributes[:name] = "#{params[:sweep][:name]} ##{run_id.to_i + 1}"
      # Copy parameters from "parent" run
      base_index = run_attributes[:inputs_attributes].keys.map {|k| k.to_i}.max + 1
      run[:inputs_attributes].each do |input_id, input_attributes|
        run_attributes[:inputs_attributes][(base_index + input_id.to_i).to_s] = input_attributes
      end
    end
  end

end
