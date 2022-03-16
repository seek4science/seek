class ObservedVariableSetsController < ApplicationController

  before_action :login_required
  before_action :observed_variable_sets_enabled?

  def index
    @observed_variable_sets = ObservedVariableSet.all
    respond_to do |format|
      format.html
    end
  end

  def show
    @observed_variable_set = ObservedVariableSet.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @observed_variable_set = ObservedVariableSet.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @observed_variable_set = ObservedVariableSet.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @observed_variable_set = ObservedVariableSet.new(observed_variable_set_params)
    if @observed_variable_set.save
      respond_to do |format|
        format.html { redirect_to @observed_variable_set}
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
      end
    end
  end

  def update
    @observed_variable_set = ObservedVariableSet.find(params[:id])
    @observed_variable_set.update(observed_variable_set_params)
    if @observed_variable_set.save
      respond_to do |format|
        format.html { redirect_to @observed_variable_set}
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def observed_variable_set_params
    params.require(:observed_variable_set).permit(:title )
  end
end
