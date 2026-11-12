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
    assay = FactoryBot.create(:experimental_assay, study: study, contributor: person, title: 'Transcriptomics')

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json

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

  test 'creators become Person entities identified by ORCID' do
    person = FactoryBot.create(:person, first_name: 'Ada', last_name: 'Lovelace', orcid: 'https://orcid.org/0000-0002-1825-0097')
    investigation = FactoryBot.create(:investigation, contributor: person, creators: [person])

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json

    person_entity = json['@graph'].detect { |e| e['@id'] == 'https://orcid.org/0000-0002-1825-0097' }

    assert_equal [{ '@id' => 'https://orcid.org/0000-0002-1825-0097' }], root_entity(json)['creator']
    assert_equal 'Person', person_entity['@type']
    assert_equal 'Ada Lovelace', person_entity['name']
    assert_equal 'Ada', person_entity['givenName']
    assert_equal 'Lovelace', person_entity['familyName']
    assert_equal 'https://orcid.org/0000-0002-1825-0097', person_entity['identifier']
  end

  test 'a person without ORCID gets a fragment id and the SEEK URL as identifier' do
    person = FactoryBot.create(:person, orcid: nil)
    investigation = FactoryBot.create(:investigation, contributor: person, creators: [person])

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json
    person_entity = json['@graph'].detect { |e| e['@id'] == "#person-#{person.id}" }

    assert_equal [{ '@id' => "#person-#{person.id}" }], root_entity(json)['creator']
    assert_equal person.rdf_seek_id, person_entity['identifier']
  end

  test 'a person creating several items appears once and the contributor stands in for missing creators' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person, creators: [person])
    FactoryBot.create(:study, investigation: investigation, contributor: person, creators: [])

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json
    reference = [{ '@id' => person.ro_crate_metadata['@id'] }]

    assert_equal(1, json['@graph'].count { |e| e['@type'] == 'Person' })
    assert_equal reference, root_entity(json)['creator']
    assert_equal reference, isa_entity(json, 'Study')['creator']
  end

  test 'givenName falls back to the full name when the first name is blank' do
    person = FactoryBot.create(:person, first_name: '', last_name: 'Lovelace')
    investigation = FactoryBot.create(:investigation, contributor: person, creators: [person])

    json = Seek::RoCrate::ISACrateBuilder.new(investigation, person.user).metadata_json
    person_entity = json['@graph'].detect { |e| e['@type'] == 'Person' }

    assert_equal 'Lovelace', person_entity['givenName']
    assert_nil person_entity['first_name']
  end

  test 'assay data files become File entities in the assay dataset directory' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, contributor: person)
    data_file = FactoryBot.create(:data_file, contributor: person, assays: [assay], description: 'Counts per gene')

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, person.user).metadata_json
    assay_entity = isa_entity(json, 'Assay')
    file_entity = json['@graph'].detect { |e| e['@type'] == 'File' }

    assert_equal "#{assay_entity['@id']}dataset/a_pdf_file.pdf", file_entity['@id']
    assert_equal data_file.title, file_entity['name']
    assert_equal 'Counts per gene', file_entity['description']
    assert_equal data_file.rdf_seek_id, file_entity['identifier']
    assert_equal 'application/pdf', file_entity['encodingFormat']
    assert_equal data_file.content_blob.file_size, file_entity['contentSize']
    assert_equal data_file.content_blob.sha1sum, file_entity['sha1']
    download = %r{/data_files/#{data_file.id}/content_blobs/#{data_file.content_blob.id}/download\z}
    assert_match download, file_entity['contentUrl']
    assert_equal [file_entity['@id']], ids_of(assay_entity['hasPart'])
    assert_not_includes ids_of(root_entity(json)['hasPart']), file_entity['@id']
  end

  test 'a URL-only data file points at the external link' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, contributor: person)
    blob = FactoryBot.create(:url_content_blob, url: 'https://example.org/counts.csv')
    FactoryBot.create(:data_file, contributor: person, assays: [assay], content_blob: blob)

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, person.user).metadata_json
    file_entity = json['@graph'].detect { |e| e['@type'] == 'File' }

    assert_equal 'https://example.org/counts.csv', file_entity['contentUrl']
    assert_nil file_entity['sha1']
  end

  test 'data files the user cannot view are skipped' do
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:public_policy))
    assay = FactoryBot.create(:assay, study: study, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:data_file, assays: [assay], policy: FactoryBot.create(:private_policy))

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, FactoryBot.create(:person).user).metadata_json

    assert_nil(json['@graph'].detect { |e| e['@type'] == 'File' })
    assert_nil isa_entity(json, 'Assay')['hasPart']
  end

  test 'assay samples become Sample entities with their attributes as PropertyValues' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:patient_sample, contributor: person, policy: FactoryBot.create(:public_policy))
    age = sample.sample_type.sample_attributes.detect { |a| a.title == 'age' }
    age.update_column(:pid, 'http://purl.obolibrary.org/obo/PATO_0000011')
    assay = FactoryBot.create(:assay, contributor: person, samples: [sample])

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, person.user).metadata_json
    sample_entity = json['@graph'].detect { |e| e['@type'] == 'Sample' }
    age_entity = json['@graph'].detect { |e| e['@id'] == "#sample-#{sample.id}-age" }
    weight_entity = json['@graph'].detect { |e| e['@id'] == "#sample-#{sample.id}-weight" }

    assert_equal "#sample-#{sample.id}", sample_entity['@id']
    assert_equal 'Fred Bloggs', sample_entity['name']
    assert_equal sample.rdf_seek_id, sample_entity['identifier']
    assert_equal [age_entity['@id'], weight_entity['@id']], ids_of(sample_entity['additionalProperty'])
    assert_equal %w[PropertyValue CharacteristicValue], [age_entity['@type'], age_entity['additionalType']]
    assert_equal 44, age_entity['value']
    assert_equal 'http://purl.obolibrary.org/obo/PATO_0000011', age_entity['propertyID']
    assert_equal 88.7, weight_entity['value']
    assert_equal %w[g gram], [weight_entity['unitCode'], weight_entity['unitText']]
    process = json['@graph'].detect { |e| e['@id'] == isa_entity(json, 'Assay')['about'].first['@id'] }
    assert_equal [sample_entity['@id']], ids_of(process['object'])
  end

  test 'a sample shared by two assays appears once and hidden samples are skipped' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: person)
    shared = FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy))
    hidden = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy))
    2.times { FactoryBot.create(:assay, study: study, contributor: person, samples: [shared, hidden]) }

    json = Seek::RoCrate::ISACrateBuilder.new(study.investigation, person.user).metadata_json
    samples = json['@graph'].select { |e| e['@type'] == 'Sample' }

    assert_equal(["#sample-#{shared.id}"], samples.map { |e| e['@id'] })
    assert_nil samples.first['additionalProperty']
  end

  test 'an assay with samples, data file and SOPs yields one LabProcess linking them' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy))
    assay = FactoryBot.create(:assay, contributor: person, samples: [sample])
    sops = 2.times.map { FactoryBot.create(:sop, contributor: person, assays: [assay], description: 'Extract RNA') }
    FactoryBot.create(:data_file, contributor: person, assays: [assay])

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, person.user).metadata_json

    puts JSON.pretty_generate(json)


    process = json['@graph'].detect { |e| e['@type'] == 'LabProcess' }
    protocol = json['@graph'].detect { |e| e['@id'] == "#protocol-#{sops.first.id}" }

    assert_equal "#process-assay-#{assay.id}", process['@id']
    assert_equal "#{assay.title} process", process['name']
    assert_equal [process['@id']], ids_of(isa_entity(json, 'Assay')['about'])
    assert_equal ["#sample-#{sample.id}"], ids_of(process['object'])
    assert_equal ids_of(isa_entity(json, 'Assay')['hasPart']), ids_of(process['result'])
    assert_equal sops.map { |sop| "#protocol-#{sop.id}" }, ids_of(process['executesLabProtocol'])
    assert_equal [person.ro_crate_metadata['@id']], ids_of(process['agent'])
    assert_equal %w[LabProtocol], Array(protocol['@type'])
    assert_equal [sops.first.title, 'Extract RNA'], protocol.values_at('name', 'description')
    assert_equal sops.first.rdf_seek_id, protocol['identifier']
    assert_equal sops.first.version, protocol['version']
  end

  test 'a bare assay has no LabProcess and an SOP-only assay keeps its protocol' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: person)
    bare = FactoryBot.create(:assay, study: study, contributor: person)
    with_sop = FactoryBot.create(:assay, study: study, contributor: person)
    sop = FactoryBot.create(:sop, contributor: person, assays: [with_sop])

    json = Seek::RoCrate::ISACrateBuilder.new(study.investigation, person.user).metadata_json
    bare_entity = json['@graph'].detect { |e| e['@id'] == "assays/#{slug(bare)}/" }
    process = json['@graph'].detect { |e| e['@type'] == 'LabProcess' }

    assert_nil bare_entity['about']
    assert_equal "#process-assay-#{with_sop.id}", process['@id']
    assert_equal ["#protocol-#{sop.id}"], ids_of(process['executesLabProtocol'])
    assert_nil process['object']
    assert_nil process['result']
  end

  test 'outgoing samples are results of the process' do
    person = FactoryBot.create(:person)
    assay = FactoryBot.create(:assay, contributor: person)
    incoming = FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy))
    outgoing = FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy))
    User.with_current_user(person.user) do
      AssayAsset.create!(assay: assay, asset: incoming, direction: AssayAsset::Direction::INCOMING)
      AssayAsset.create!(assay: assay, asset: outgoing, direction: AssayAsset::Direction::OUTGOING)
    end

    json = Seek::RoCrate::ISACrateBuilder.new(assay.investigation, person.user).metadata_json
    process = json['@graph'].detect { |e| e['@type'] == 'LabProcess' }

    assert_equal ["#sample-#{incoming.id}"], ids_of(process['object'])
    assert_equal ["#sample-#{outgoing.id}"], ids_of(process['result'])
  end

  private

  def slug(resource)
    "#{resource.id}-#{resource.title.parameterize}"
  end

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
