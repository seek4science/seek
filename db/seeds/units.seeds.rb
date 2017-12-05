ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "units")
units = YAML.load_file(File.join(Rails.root, 'config/default_data/','units.yml')).values

units.each do |unit|
  symbol=unit['symbol']
  comment=unit['comment']
  order=unit['order']
  title=unit['title']
  factors_studied=unit['factors_studied']
  factors_studied=true if factors_studied.nil?
  unit = Unit.find_or_initialize_by(symbol:symbol)
  unit.update_attributes(comment:comment,order:order,title:title,factors_studied:factors_studied)

end

puts "Seeded units"