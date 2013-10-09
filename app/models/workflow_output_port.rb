class WorkflowOutputPort < ActiveRecord::Base
  belongs_to :port_type, :class_name => 'WorkflowOutputPortType'
  belongs_to :example_data_file, :class_name => 'DataFile'
  belongs_to :workflow
end