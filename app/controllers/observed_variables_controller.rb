class ObservedVariablesController < ApplicationController

  before_action :login_required
  before_action :observed_variables_enabled?

  def index
    @observed_variables = ObservedVariable.all
    respond_to do |format|
      format.html
    end
  end

  def show
    @observed_variable = ObservedVariable.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @observed_variable = ObservedVariable.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @observed_variable = ObservedVariable.new
    if params[:observed_variable_set_id]
      @observed_variable.observed_variable_set = ObservedVariableSet.find(params[:observed_variable_set_id])
    end
    respond_to do |format|
      format.html
    end
  end

  def create
    @observed_variable = ObservedVariable.new(observed_variable_params)
    if @observed_variable.save
      respond_to do |format|
        format.html { redirect_to @observed_variable}
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
      end
    end
  end

  def update
    @observed_variable = ObservedVariable.find(params[:id])
    @observed_variable.update(observed_variable_params)
    if @observed_variable.save
      respond_to do |format|
        format.html { redirect_to @observed_variable}
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def observed_variable_params
    params.require(:observed_variable).permit(:variable_id, :variable_name, :variable_an, :trait,
                                              :trait_an, :trait_entity, :trait_entity_an, :trait_attribute,
                                              :trait_attribute_an, :method, :method_an, :method_description,
                                              :method_reference, :scale, :scale_an, :timescale, :observed_variable_set_id)
  end

end
