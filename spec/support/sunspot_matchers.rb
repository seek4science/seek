RSpec.configure do |c|
  c.include SunspotMatchers
  c.before do
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end
end