
count = ModelType.count
titles = YAML.load_file(File.join(Rails.root, 'config/default_data/model_types.yml')).values.collect { |x| x['title'] }
titles.each do |title|
  # some older db's may not include the ODE,PDE for Ordinary or Partial differential equations
  unless ModelType.find_by(title: title.gsub(' (ODE)', '')) || ModelType.find_by(title: title.gsub(' (PDE)', ''))
    ModelType.find_or_create_by(title: title)
  end
end

# fix those pesky Ordinary or Partial differential equations
if model_type = ModelType.find_by(title: 'Ordinary differential equations')
  model_type.update_attributes(title: 'Ordinary differential equations (ODE)')
end

if model_type = ModelType.find_by(title: 'Partial differential equations')
  model_type.update_attributes(title: 'Partial differential equations (PDE)')
end

puts "Seeded #{ModelType.count - count} model types"
