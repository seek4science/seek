class WorkflowClassesController < ApplicationController
  def create
    @workflow_class = WorkflowClass.new(workflow_class_params)
    @workflow_class.contributor = current_person

    @workflow_class.save
    respond_to do |format|
      format.js
    end
  end

  def update
  end

  def destroy
  end

  def index
  end

  private

  def workflow_class_params
    params.require(:workflow_class).permit(:title, :alternate_name, :identifier, :url)
  end
end
