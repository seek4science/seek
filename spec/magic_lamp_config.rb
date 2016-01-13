require "database_cleaner"
require 'factory_girl'
FactoryGirl.find_definitions #It looks like requiring factory_girl _should_ do this automatically, but it doesn't seem to work

FactoryGirl.class_eval do
  def self.create_with_privileged_mode *args
    disable_authorization_checks {create_without_privileged_mode *args}
  end

  def self.build_with_privileged_mode *args
    disable_authorization_checks {build_without_privileged_mode *args}
  end

  class_alias_method_chain :create, :privileged_mode
  class_alias_method_chain :build, :privileged_mode
end


MagicLamp.configure do |config|

  #Dir[Rails.root.join("spec", "support", "magic_lamp_helpers/**/*.rb")].each { |f| load f }

  DatabaseCleaner.strategy = :transaction

  config.before_each do
    DatabaseCleaner.start
  end

  config.after_each do
    DatabaseCleaner.clean
  end

end