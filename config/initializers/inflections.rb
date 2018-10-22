  # Be sure to restart your server when you modify this file.
SEEK::Application.configure do

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "specimen","specimens"
  end
end
