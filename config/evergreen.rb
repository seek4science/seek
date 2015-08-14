Evergreen.configure do |config|
  config.application  = Evergreen::Application
  config.driver       = :selenium
  config.public_dir   = 'app/assets/javascripts/'
  config.spec_dir     = 'spec/javascripts'
  config.template_dir = 'spec/javascripts/templates'
  config.helper_dir   = 'spec/javascripts/helpers'
  config.mounted_at   = ""
end