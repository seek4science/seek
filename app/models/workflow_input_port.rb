class WorkflowInputPort < ActiveRecord::Base
  belongs_to :type, :class_name => 'WorkflowInputPortType'
  belongs_to :example_data_file, :class_name => 'DataFile'
  belongs_to :workflow

  before_save :set_version

  private

  def set_version
    self.workflow_version = self.workflow.version
  end
end