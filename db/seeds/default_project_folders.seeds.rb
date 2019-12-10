
titles = YAML.load_file(File.join(Rails.root, 'config/default_data/default_project_folders_v2.yml')).values.collect { |x| x['title'] }

titles.each do |title|
  unless DefaultProjectFolder.find_by(title: title)
    DefaultProjectFolder.find_or_create_by(title: title)
  end
end

puts "Seeded default project folders"



