class WorkflowOutputPort < ActiveRecord::Base
  belongs_to :type, :class_name => 'WorkflowOutputPortType'
  belongs_to :example_data_file, :class_name => 'DataFile'
end