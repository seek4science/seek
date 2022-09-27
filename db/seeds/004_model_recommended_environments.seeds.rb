count = RecommendedModelEnvironment.count
titles = YAML.load_file(File.join(Rails.root, 'config/default_data/model_recommended_environments.yml')).values.collect { |x| x['title'] }
titles.each do |title|
  RecommendedModelEnvironment.find_or_create_by(title: title)
end

if (RecommendedModelEnvironment.count - count) > 0
  puts "Seeded #{RecommendedModelEnvironment.count - count} model recommended environments"
end
