require 'test_helper'

class CultureGrowthTypeTest < ActiveSupport::TestCase
  test 'to rdf' do
    object = FactoryBot.create(:culture_growth_type)
    rdf = object.to_rdf
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert graph.statements.count > 1
    assert_equal RDF::URI.new("http://localhost:3000/culture_growth_types/#{object.id}"), graph.statements.first.subject
  end
end
