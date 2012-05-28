def in_memory_database?
  Rails.env == "test" and 
    Rails.configuration.database_configuration['test']['database'] == ':memory:'
end
      
if in_memory_database?
  puts "creating sqlite in memory database"
  load "#{Rails.root}/db/schema.rb"
end
