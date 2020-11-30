ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "workflow_classes")

puts "Seeded workflow classes"
