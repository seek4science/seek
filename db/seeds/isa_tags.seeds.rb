tags = YAML.load_file(File.join(Rails.root, 'config/default_data/','isa_tags.yml')).values

tags.each do |tag|
  unit = IsaTag.find_or_create_by(title: tag['title'])
end

puts "Seeded isa tags"