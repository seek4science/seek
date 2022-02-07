classes = YAML.load(File.read(File.join(Rails.root, 'config', 'default_data' ,'workflow_data_file_relationships.yml')))

classes.each do |key, data|
  # DB-agnostic way to match key in a case-insensitive way
  relationship = WorkflowDataFileRelationship.where(WorkflowDataFileRelationship.arel_table[:key].matches(data['key'])).first_or_initialize

  disable_authorization_checks { relationship.update_attributes!(data) }
end

puts "Seeded workflow to data file relationships"