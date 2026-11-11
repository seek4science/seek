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
    assert_equal investigation.id.to_s, root['identifier']
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

  test 'studies and assays are directory datasets nested under the root' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: person, title: 'Growth')
    assay = FactoryBot.create(:assay, study: study, contributor: person, title: 'Transcriptomics')

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json

    puts json.inspect

    study_entity = isa_entity(json, 'Study')
    assay_entity = isa_entity(json, 'Assay')

    assert_equal "studies/#{study.id}-growth/", study_entity['@id']
    assert_equal "assays/#{assay.id}-transcriptomics/", assay_entity['@id']
    assert_equal 'Dataset', study_entity['@type']
    assert_equal study.id.to_s, study_entity['identifier']
    assert_equal study.rdf_seek_id, study_entity['url']
    assert_equal 'Growth', study_entity['name']
    assert_equal assay.assay_type_uri, assay_entity['measurementMethod']
    assert_equal assay.technology_type_uri, assay_entity['measurementTechnique']
    assert_equal [study_entity['@id'], assay_entity['@id']], ids_of(root_entity(json)['hasPart'])
    assert_equal [assay_entity['@id']], ids_of(study_entity['hasPart'])
    assert_nil assay_entity['hasPart']
  end

  test 'studies and assays the user cannot view are skipped' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:private_policy))
    public_study = FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:assay, study: public_study, policy: FactoryBot.create(:private_policy))

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, FactoryBot.create(:person).user).metadata_json

    expected = ["studies/#{public_study.id}-#{public_study.title.parameterize}/"]
    assert_equal expected, ids_of(root_entity(json)['hasPart'])
    assert_nil isa_entity(json, 'Assay')
  end

  test 'assays in a stream are nested under the stream assay' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: person)
    stream = FactoryBot.create(:assay_stream, study: study, contributor: person)
    child = FactoryBot.create(:assay, study: study, contributor: person, assay_stream: stream)

    json = Seek::RoCrate::ISACrateBuilder.new(study.investigation, person.user).metadata_json
    stream_entity = json['@graph'].detect { |e| e['@id'] == "assays/#{stream.id}-#{stream.title.parameterize}/" }
    child_id = "assays/#{child.id}-#{child.title.parameterize}/"

    assert_equal [child_id], ids_of(stream_entity['hasPart'])
    assert_equal [stream_entity['@id']], ids_of(isa_entity(json, 'Study')['hasPart'])
    assert_includes ids_of(root_entity(json)['hasPart']), child_id
  end

  test 'directory ids are unique and filesystem safe' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: person, title: 'Heat stress: 35°C / 40°C (pilot)')
    assays = 2.times.map { FactoryBot.create(:assay, study: study, contributor: person, title: 'Same title') }

    json = Seek::RoCrate::ISACrateBuilder.new(study.investigation, person.user).metadata_json
    ids = ids_of(root_entity(json)['hasPart'])

    assert_equal "studies/#{study.id}-heat-stress-35-c-40-c-pilot/", ids.first
    assert_equal assays.map { |a| "assays/#{a.id}-same-title/" }, ids.drop(1)
    ids.each { |id| assert_match %r{\A[A-Za-z0-9_\-./]+\z}, id }
  end

  private

  def root_entity(json)
    json['@graph'].detect { |e| e['@id'] == './' }
  end

  def isa_entity(json, type_name)
    json['@graph'].detect { |e| e['additionalType'] == ["#{JERM}#{type_name}", type_name] }
  end

  def ids_of(references)
    references.map { |ref| ref['@id'] }
  end
end
