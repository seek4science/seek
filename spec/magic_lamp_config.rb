require 'database_cleaner'

MagicLamp.configure do |config|
  #Dir[Rails.root.join("spec", "support", "magic_lamp_helpers/**/*.rb")].each { |f| load f }

  DatabaseCleaner.strategy = :truncation

  config.before_each do
    DatabaseCleaner.start
  end

  config.after_each do
    DatabaseCleaner.clean
  end
end
