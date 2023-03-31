class WorkflowClassesController < ApplicationController
  include Seek::DestroyHandling

  before_action :find_and_authorize_requested_item, only: [:edit, :update, :destroy]

  def create
    @workflow_class = WorkflowClass.new(workflow_class_params)
    @workflow_class.contributor = current_person

    if @workflow_class.save
      flash[:notice] = "The #{WorkflowClass.model_name.human} was successfully created."
      respond_to do |format|
        format.html { redirect_to workflow_classes_path }
        format.js
      end
    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    if @workflow_class.update(workflow_class_params)
      flash[:notice] = "The #{WorkflowClass.model_name.human} was successfully updated."
      respond_to do |format|
        format.html { redirect_to workflow_classes_path }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit', status: :unprocessable_entity }
      end
    end
  end

  def new
    @workflow_class = WorkflowClass.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def index
    @workflow_classes = WorkflowClass.order(extractor: :desc).all
  end

  private

  def handle_authorization_failure_redirect(*_)
    redirect_to workflow_classes_path
  end

  def workflow_class_params
    params.require(:workflow_class).permit(:title, :alternate_name, :identifier, :url, :logo_image)
  end
end
