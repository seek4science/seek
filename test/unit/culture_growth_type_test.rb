require 'test_helper'

class CultureGrowthTypeTest < ActiveSupport::TestCase
  test 'to rdf' do
    object = Factory(:culture_growth_type)
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/culture_growth_types/#{object.id}"), reader.statements.first.subject
    end
  end
end
