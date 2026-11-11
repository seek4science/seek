require 'test_helper'

class ISACrateBuilderTest < ActiveSupport::TestCase
  JERM = Seek::RoCrate::ISACrateBuilder::JERM

  test 'root dataset describes the investigation' do
    investigation = FactoryBot.create(:investigation, title: 'Heat stress in barley', description: 'Pilot study')

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, investigation.contributor.user).metadata_json
    root = root_entity(json)

    assert_equal 'Dataset', root['@type']
    assert_equal ["#{JERM}Investigation", 'Investigation'], root['additionalType']
    assert_equal 'Heat stress in barley', root['name']
    assert_equal 'Pilot study', root['description']
    assert_equal investigation.rdf_seek_id, root['identifier']
    assert_equal investigation.rdf_seek_id, root['url']
    assert_equal Seek::RoCrate::ISACrateBuilder::DEFAULT_LICENSE, root['license']
    assert_nothing_raised { Time.iso8601(root['datePublished']) }
    assert_equal [], root['hasPart']
  end

  test 'context is RO-Crate 1.2 plus the bioschemas terms in use' do
    json = Seek::RoCrate::ISACrateBuilder.new(FactoryBot.create(:investigation), nil).metadata_json

    assert_equal 'https://w3id.org/ro/crate/1.2/context', json['@context'].first
    assert_equal %w[Sample LabProtocol LabProcess executesLabProtocol], json['@context'].last.keys
    assert_equal 'https://bioschemas.org/Sample', json['@context'].last['Sample']
  end

  test 'metadata descriptor conforms to RO-Crate 1.2' do
    json = Seek::RoCrate::ISACrateBuilder.new(FactoryBot.create(:investigation), nil).metadata_json
    descriptor = json['@graph'].detect { |e| e['@id'] == 'ro-crate-metadata.json' }

    assert_equal 'https://w3id.org/ro/crate/1.2', descriptor['conformsTo']['@id']
    assert_equal './', descriptor['about']['@id']
  end

  test 'blank description falls back to the title' do
    investigation = FactoryBot.create(:investigation, title: 'Only a title', description: nil)

    root = root_entity(Seek::RoCrate::ISACrateBuilder.new(investigation, nil).metadata_json)

    assert_equal 'Only a title', root['description']
  end

  test 'investigation exposes the crate' do
    investigation = FactoryBot.create(:investigation)

    crate = investigation.to_isa_ro_crate(investigation.contributor.user)

    assert_kind_of ROCrate::Crate, crate
    assert_equal investigation.title, crate['name']
  end

  private

  def root_entity(json)
    json['@graph'].detect { |e| e['@id'] == './' }
  end
end
