classes = YAML.load(File.read(File.join(Rails.root, 'config', 'default_data' ,'workflow_classes.yml')))

classes.each do |key, data|
  # DB-agnostic way to match key in a case-insensitive way
  workflow_class = WorkflowClass.where(WorkflowClass.arel_table[:key].matches(data['key'])).first_or_initialize

  disable_authorization_checks { workflow_class.update_attributes!(data) }
end

puts "Seeded workflow classes"
