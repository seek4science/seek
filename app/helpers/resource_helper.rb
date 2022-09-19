module ResourceHelper
  # returns the instance for the resource for the controller, e.g @data_file for data_files
  def resource_for_controller(c = controller_name)
    instance_variable_get("@#{c.singularize}")
  end

  # returns the current version of the resource for the controller, e.g @display_data_file for data_files
  def versioned_resource_for_controller(c = controller_name)
    instance_variable_get("@display_#{c.singularize}")
  end
end
