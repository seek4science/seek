require 'test_helper'

class RorSchemaOrgTest < ActiveSupport::TestCase
  setup do
    record = JSON.parse(File.read("#{Rails.root}/test/fixtures/files/mocking/ror_response.json"))
    @json = Ror::SchemaOrg.new(record).to_h
  end

  test 'organisation' do
    assert_equal 'https://ror.org/027m9bs27', @json['@id']
    assert_equal %w[Organization EducationalOrganization], @json['@type']
    assert_equal 'University of Manchester', @json['name']
    assert_includes @json['alternateName'], { '@value' => 'Prifysgol Manceinion', '@language' => 'cy' }
    assert_equal({ '@id' => 'http://www.manchester.ac.uk/' }, @json['url'])
    assert_equal '1824', @json['foundingDate']
  end

  test 'equivalent records' do
    assert_equal %w[http://en.wikipedia.org/wiki/University_of_Manchester http://www.wikidata.org/entity/Q230899
                    https://isni.org/isni/0000000121662407 https://doi.org/10.13039/501100000770],
                 @json['sameAs'].map { |same| same['@id'] }
  end

  test 'location' do
    place = @json['location'].first
    assert_equal 'https://sws.geonames.org/2643123/', place['@id']
    assert_equal 'Manchester', place['address']['addressLocality']
    assert_equal 'GB', place['address']['addressCountry']
    assert_equal 53.48095, place['geo']['latitude']
  end

  test 'parent and child organisations, but not related ones' do
    assert_includes @json['subOrganization'],
                    { '@id' => 'https://ror.org/03xxxrq06', 'name' => 'Manchester School of Architecture' }
    assert_nil @json['parentOrganization']
    refute(@json.values.flatten.any? { |v| v.is_a?(Hash) && v['@id'] == 'https://ror.org/02j7n9748' })
  end

  test 'valid json-ld' do
    statements = RDF::Reader.for(:jsonld).new(Ror::SchemaOrg.new(
      JSON.parse(File.read("#{Rails.root}/test/fixtures/files/mocking/ror_response.json"))
    ).to_json_ld).statements.to_a
    refute_empty statements
  end
end
