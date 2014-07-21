RSpec.configure do |c|
  c.include SunspotMatchers
  original_solr_config = Seek::Config.solr_enabled
  c.before(:all) do
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
    #need to put after Sunspot config?
    Seek::Config.solr_enabled = true
  end
  c.after(:all) do
    Seek::Config.solr_enabled = original_solr_config
  end
end