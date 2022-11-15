ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "units")
units = YAML.load_file(File.join(Rails.root, 'config/default_data/','units.yml')).values

units.each do |unit|
  symbol=unit['symbol']
  comment=unit['comment']
  order=unit['order']
  title=unit['title']
  unit = Unit.find_or_initialize_by(symbol:symbol)
  unit.update(comment:comment,order:order,title:title)
end

puts "Seeded units"