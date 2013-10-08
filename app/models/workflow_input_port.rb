class WorkflowInputPort < ActiveRecord::Base
  belongs_to :type, :class_name => 'WorkflowInputPortType'
  belongs_to :example_data_file, :class_name => 'DataFile'
end