require 'test_helper'

# Explores how SEEK ISA records map onto an RO-Crate shaped after the ISA RO-Crate profile with the
# ARC directory layout: the Investigation is the root dataset, studies and assays are subdirectory
# datasets, data files sit in the assay's dataset directory, extended metadata becomes PropertyValue
# entities, and samples, SOPs and the assay run become bioschemas Sample, LabProtocol and LabProcess.
class RoCrateExploringTest < ActiveSupport::TestCase
  JERM = 'https://jermontology.org/ontology/JERMOntology#'.freeze
  FAIR_PUBLICATION_PID = 'http://fairbydesign.nl/ontology/associated_publication'.freeze
  AGE_PID = 'http://fairbydesign.nl/ontology/age'.freeze
  SITE_BASE_HOST = 'https://sandbox.fairdomhub.org'.freeze # ARC tool rejects localhost URLs, so use a public test site for the crate's URLs
  RO_CRATE_VERSION = '1.2'.freeze
  RO_CRATE_CONTEXT = "https://w3id.org/ro/crate/#{RO_CRATE_VERSION}/context".freeze
  # ARC requires a license on the investigation, which is the root dataset. Investigations, studies and
  # assays carry no license in SEEK; only the assets linked to them do, so the root gets a generic statement.
  DEFAULT_LICENSE = 'No single license applies to this crate as a whole. ' \
                    'Each included item is subject to its own license.'.freeze
  BIOSCHEMAS_TERMS = {
    'Sample' => 'https://bioschemas.org/Sample',
    'LabProtocol' => 'https://bioschemas.org/LabProtocol',
    'LabProcess' => 'https://bioschemas.org/LabProcess',
    'executesLabProtocol' => 'https://bioschemas.org/properties/executesLabProtocol'
  }.freeze

  setup do
    @original_site_base_host = Seek::Config.site_base_host
    Seek::Config.site_base_host = SITE_BASE_HOST
  end

  teardown do
    Seek::Config.site_base_host = @original_site_base_host
  end

  test 'investigation is the root dataset' do
    investigation = setup_test_case_investigation
    assert_equal 2, investigation.studies.count

    json = JSON.parse(build_crate(investigation).metadata.generate)
    graph = json['@graph']

    assert_equal [RO_CRATE_CONTEXT, BIOSCHEMAS_TERMS], json['@context']
    descriptor = find_entity(graph, 'ro-crate-metadata.json')
    assert_equal "https://w3id.org/ro/crate/#{RO_CRATE_VERSION}", descriptor['conformsTo']['@id']

    root = find_entity(graph, './')
    assert_equal 'Dataset', root['@type']
    assert_isa_type root, 'Investigation'
    assert_equal investigation.id.to_s, root['identifier']
    assert_equal "#{SITE_BASE_HOST}/investigations/#{investigation.id}", root['url']
    assert_equal investigation.title, root['name']
    assert_equal investigation.description, root['description']
    assert_equal DEFAULT_LICENSE, root['license']
    assert_nothing_raised { Time.iso8601(root['datePublished']) }

    # the root lists study and assay directories, but never the data files inside them
    assert_equal study_and_assay_dirs(graph).sort, part_ids(root).sort
    assert(part_ids(root).all? { |id| id.end_with?('/') })
    assert_no_dangling_references graph
  end

  test 'study and assay are subdirectory datasets' do
    study = FactoryBot.create(:study, title: 'Growth', description: 'Plants grown at 35C and 40C.')
    assay = FactoryBot.create(:assay, title: 'Transcriptomics', study: study)
    data_file = FactoryBot.create(:data_file, assays: [assay])
    filename = data_file.content_blob.original_filename

    graph = generate_graph(build_crate(study.investigation))

    study_json = find_entity(graph, "studies/#{study.id}-growth/")
    assert_equal 'Dataset', study_json['@type']
    assert_isa_type study_json, 'Study'
    assert_equal study.id.to_s, study_json['identifier']
    assert_equal "#{SITE_BASE_HOST}/studies/#{study.id}", study_json['url']
    assert_equal study.title, study_json['name']
    assert_equal study.description, study_json['description']
    assert_equal ["assays/#{assay.id}-transcriptomics/"], part_ids(study_json)

    assay_json = find_entity(graph, "assays/#{assay.id}-transcriptomics/")
    assert_isa_type assay_json, 'Assay'
    assert_equal assay.id.to_s, assay_json['identifier']
    assert_equal "#{SITE_BASE_HOST}/assays/#{assay.id}", assay_json['url']
    assert_equal assay.assay_type_uri, assay_json['measurementMethod']
    assert_equal ["assays/#{assay.id}-transcriptomics/dataset/#{filename}"], part_ids(assay_json)

    file_json = find_entity(graph, "assays/#{assay.id}-transcriptomics/dataset/#{filename}")
    assert_equal 'File', file_json['@type']
    assert_equal data_file.title, file_json['name']
    assert_equal data_file.rdf_seek_id, file_json['identifier']
    assert_equal data_file.content_blob.content_type, file_json['encodingFormat']
    assert_not file_json.key?('description'), 'blank values are left out rather than written as null'
  end

  test 'extended metadata becomes PropertyValue entities' do
    emt = FactoryBot.create(:simple_assay_extended_metadata_type)
    emt.extended_metadata_attributes.find_by(title: 'age').update!(pid: AGE_PID)
    extended_metadata = ExtendedMetadata.new(extended_metadata_type: emt, data: { name: 'Fred', age: 25 })
    assay = FactoryBot.create(:assay, title: 'Assay with Extended Metadata', extended_metadata: extended_metadata)

    graph = generate_graph(build_crate(assay.study.investigation))
    assay_json = find_entity(graph, "assays/#{assay.id}-assay-with-extended-metadata/")

    # the type has three attributes, but the unset datetime is not exported
    references = assay_json['additionalProperty']
    assert_equal 2, references.length
    properties = references.map { |ref| find_entity(graph, ref['@id']) }
    assert(properties.all? { |p| p['@type'] == 'PropertyValue' })

    # an attribute without a pid falls back to a SEEK link
    name_property = properties.detect { |p| p['name'] == 'Name' }
    assert_equal 'Fred', name_property['value']
    assert_equal "#{assay.rdf_seek_id}#extended_metadata/name", name_property['propertyID']

    # an attribute with a pid uses that IRI
    age_property = properties.detect { |p| p['name'] == 'Age' }
    assert_equal 25, age_property['value']
    assert_equal AGE_PID, age_property['propertyID']
  end

  test 'creators become Person entities' do
    assay = FactoryBot.create(:max_assay)
    creator = assay.creators.first
    assert_equal 'Some', creator.first_name

    graph = generate_graph(build_crate(assay.study.investigation))
    assay_json = find_entity(graph, "assays/#{slug(assay)}/")

    creator_ids = assay_json['creator'].map { |c| c['@id'] }
    assert_equal [creator.ro_crate_metadata['@id']], creator_ids

    person_json = find_entity(graph, creator_ids.first)
    assert_equal 'Person', person_json['@type']
    assert_equal creator.first_name, person_json['givenName']
    assert_equal creator.last_name, person_json['familyName']
    assert_equal creator.name, person_json['name']
    assert_no_dangling_references graph
  end

  test 'samples and sops become a LabProcess on the assay' do
    assay = FactoryBot.create(:max_assay)
    sample = assay.samples.first
    sop = assay.sops.first
    assert sample && sop

    graph = generate_graph(build_crate(assay.study.investigation))
    assay_json = find_entity(graph, "assays/#{slug(assay)}/")

    process_json = find_entity(graph, assay_json['about'].first['@id'])
    assert_equal 'LabProcess', process_json['@type']
    assert_equal [sample_id(sample)], ids_of(process_json['object'])
    assert_equal part_ids(assay_json), ids_of(process_json['result'])
    assert_equal assay_json['creator'], process_json['agent']

    sample_json = find_entity(graph, sample_id(sample))
    assert_equal 'Sample', sample_json['@type']
    assert_equal sample.title, sample_json['name']
    assert_equal sample.rdf_seek_id, sample_json['identifier']

    protocol_json = find_entity(graph, process_json['executesLabProtocol']['@id'])
    assert_equal 'LabProtocol', protocol_json['@type']
    assert_equal sop.title, protocol_json['name']
    assert_equal sop.rdf_seek_id, protocol_json['identifier']
  end

  test 'investigation with studies and assays including extended metadata' do
    investigation = setup_test_case_investigation
    studies = investigation.studies
    assert(studies.all? { |s| s.assays.any? })

    graph = generate_graph(build_crate(investigation))
    root = find_entity(graph, './')

    publication = resolve_properties(graph, root).detect { |p| p['propertyID'] == FAIR_PUBLICATION_PID }
    assert_equal 'PropertyValue', publication['@type']
    assert_equal 'Associated publication', publication['name']
    assert_equal '10.1371/journal.pone.0071377', publication['value']

    studies.each do |study|
      study_json = find_entity(graph, "studies/#{slug(study)}/")
      assert_equal study.title, study_json['name']
      assert_equal study.assays.map { |a| "assays/#{slug(a)}/" }.sort, part_ids(study_json).sort
      assert(resolve_properties(graph, study_json).any? { |p| p['propertyID'].start_with?('http://fairbydesign.nl/') })
    end

    assays_with_files = studies.flat_map(&:assays).select { |a| a.data_files.any? }
    assert assays_with_files.any?
    assays_with_files.each { |assay| assert_assay_files_linked(graph, assay) }
  end

  private

  def generate_graph(crate)
    JSON.parse(crate.metadata.generate)['@graph']
  end

  def find_entity(graph, id)
    entity = graph.detect { |e| e['@id'] == id }
    assert entity, "no entity with @id #{id} in graph (ids: #{graph.map { |e| e['@id'] }.inspect})"
    entity
  end

  def part_ids(entity)
    ids_of(entity['hasPart'])
  end

  def ids_of(references)
    Array(references).map { |ref| ref['@id'] }
  end

  def resolve_properties(graph, entity)
    Array(entity['additionalProperty']).map { |ref| find_entity(graph, ref['@id']) }
  end

  def study_and_assay_dirs(graph)
    graph.map { |e| e['@id'] }.select { |id| id.start_with?('studies/', 'assays/') && id.end_with?('/') }
  end

  def assert_isa_type(entity, name)
    assert_equal ["#{JERM}#{name}", name], entity['additionalType']
  end

  # The assay entity lists exactly the assay's data files, inside its dataset directory, under hasPart.
  def assert_assay_files_linked(graph, assay)
    dir = "assays/#{slug(assay)}/"
    expected = assay.data_files.map { |df| "#{dir}dataset/#{df.content_blob.original_filename}" }.sort
    assert_equal expected, part_ids(find_entity(graph, dir)).sort
  end

  # Every { "@id" => ... } reference in the graph points at an entity in the graph or an absolute URI.
  def assert_no_dangling_references(graph)
    ids = graph.map { |e| e['@id'] }
    graph.each do |entity|
      entity.except('@id').values.flatten.each do |value|
        next unless value.is_a?(Hash) && value.keys == ['@id']

        id = value['@id']
        assert ids.include?(id) || id.match?(%r{\Ahttps?://}), "dangling reference #{id} in #{entity['@id']}"
      end
    end
  end

  # --- crate construction ---

  # additionalType is a list: the IRI of the JERM ontology term, plus the bare name ("Investigation",
  # "Study" or "Assay"). The bare name is needed because ARC tools (arctrl) only recognise a Dataset as
  # a study or an assay by that exact string; with the JERM IRI alone they silently skip the entity.
  def isa_type(name)
    ["#{JERM}#{name}", name]
  end

  # Directory name: SEEK id, then the title lowercased with runs of spaces and punctuation collapsed
  # to one hyphen, e.g. "42-heat-stress-in-barley". The id keeps names unique without any clash rule.
  def slug(resource)
    "#{resource.id}-#{resource.title.parameterize}"
  end

  def sample_id(sample)
    "#sample-#{sample.id}"
  end

  # Assigns only present values, so the crate carries no null or empty properties.
  def set(entity, properties)
    properties.each { |k, v| entity[k] = v unless v.nil? || (v.respond_to?(:empty?) && v.empty?) }
    entity
  end

  def build_crate(investigation)
    crate = ::ROCrate::Crate.new(version: RO_CRATE_VERSION)
    crate.metadata.context = [RO_CRATE_CONTEXT, BIOSCHEMAS_TERMS]
    set(crate, root_properties(crate, investigation))
    top_level = investigation.studies.flat_map { |study| add_study(crate, study) }
    keep_root_parts(crate, top_level.map(&:reference))
    # Writes the generated metadata to tmp/ro-crate-metadata.json for inspection; comment out when not needed.
    File.write(Rails.root.join('tmp/ro-crate-metadata.json'), JSON.pretty_generate(JSON.parse(crate.metadata.generate)))
    crate
  end

  def root_properties(crate, investigation)
    isa_properties('Investigation', investigation).merge(
      'license' => DEFAULT_LICENSE,
      'datePublished' => Time.now.utc.iso8601,
      'creator' => people(crate, investigation.creators),
      'additionalProperty' => property_values(crate, investigation, "investigation-#{investigation.id}")
    )
  end

  # The gem rebuilds the root hasPart from every data entity on write; the root should only list
  # the study and assay directories.
  def keep_root_parts(crate, parts)
    crate.define_singleton_method(:properties) do
      ::ROCrate::Entity.instance_method(:properties).bind(self).call.merge('hasPart' => parts)
    end
  end

  # Returns the study entity followed by its assay entities, all of which sit at the crate root.
  def add_study(crate, study)
    entity = isa_dataset(crate, "studies/#{slug(study)}/", 'Study', study)
    set(entity, 'creator' => people(crate, study.creators),
                'additionalProperty' => property_values(crate, study, "study-#{study.id}"))
    assays = study.assays.map { |assay| add_assay(crate, assay) }
    entity['hasPart'] = assays.map(&:reference)
    [entity, *assays]
  end

  def add_assay(crate, assay)
    dir = "assays/#{slug(assay)}/"
    entity = isa_dataset(crate, dir, 'Assay', assay)
    set(entity, 'creator' => people(crate, assay.creators),
                'measurementMethod' => assay.assay_type_uri,
                'measurementTechnique' => assay.technology_type_uri,
                'additionalProperty' => property_values(crate, assay, "assay-#{assay.id}"))
    files = assay.data_files.map { |df| add_file(crate, dir, df) }
    entity['hasPart'] = files.map(&:reference)
    add_process(crate, entity, assay, files)
  end

  def isa_dataset(crate, id, type_name, resource)
    entity = ::ROCrate::DataEntity.new(crate)
    entity.id = id
    entity.type = 'Dataset'
    set(entity, isa_properties(type_name, resource))
    crate.add_data_entity(entity)
    entity
  end

  # identifier is the bare SEEK id on every level and url the SEEK URL. ARC tools use a study's or
  # assay's identifier as a directory name and allow only letters, digits, underscore, dash and space
  # in it, so a URL is rejected there; the investigation follows the same rule for consistency.
  def isa_properties(type_name, resource)
    { 'additionalType' => isa_type(type_name),
      'identifier' => resource.id.to_s,
      'url' => resource.rdf_seek_id,
      'name' => resource.title,
      'description' => resource.description }
  end

  def add_file(crate, dir, data_file)
    blob = data_file.content_blob
    entity = ::ROCrate::DataEntity.new(crate, blob.filepath, "#{dir}dataset/#{blob.original_filename}",
                                       '@type' => 'File')
    set(entity, 'name' => data_file.title,
                'description' => data_file.description,
                'encodingFormat' => blob.content_type,
                'identifier' => data_file.rdf_seek_id)
    crate.add_data_entity(entity)
    entity
  end

  # One LabProcess per assay, linked from the assay entity through about: its samples in, its data
  # files out, executing the first linked SOP. Assays without samples or data files get none.
  def add_process(crate, assay_entity, assay, files)
    samples = assay.samples.map { |sample| add_sample(crate, sample) }
    return assay_entity if samples.empty? && files.empty?

    entity = contextual(crate, "#process-assay-#{assay.id}", 'LabProcess',
                        'name' => "#{assay.title} process",
                        'object' => samples.map(&:reference),
                        'result' => files.map(&:reference),
                        'agent' => people(crate, assay.creators),
                        'executesLabProtocol' => protocol_reference(crate, assay))
    assay_entity['about'] = [entity.reference]
    assay_entity
  end

  def protocol_reference(crate, assay)
    sop = assay.sops.first
    add_protocol(crate, sop).reference if sop
  end

  def contextual(crate, id, type, properties)
    entity = ::ROCrate::ContextualEntity.new(crate, id, '@type' => type)
    set(entity, properties)
    crate.add_contextual_entity(entity)
    entity
  end

  def add_sample(crate, sample)
    contextual(crate, sample_id(sample), 'Sample', 'name' => sample.title, 'identifier' => sample.rdf_seek_id)
  end

  def add_protocol(crate, sop)
    contextual(crate, "#protocol-#{sop.id}", 'LabProtocol',
               'name' => sop.title, 'description' => sop.description, 'identifier' => sop.rdf_seek_id)
  end

  # Person entities are shared: a person creating several records appears once in the graph.
  def people(crate, people)
    people.map do |person|
      id = person.ro_crate_metadata['@id']
      existing = crate.contextual_entities.detect { |e| e.id == id }
      existing ? existing.reference : add_person(crate, id, person).reference
    end
  end

  def add_person(crate, id, person)
    entity = ::ROCrate::Person.new(crate, id)
    set(entity, 'name' => person.name, 'givenName' => person.first_name, 'familyName' => person.last_name,
                'identifier' => person.ro_crate_metadata[:identifier])
    crate.add_contextual_entity(entity)
  end

  # Extended metadata values as PropertyValue entities with ids like "#assay-3-facility", identified
  # by the attribute's persistent identifier when it has one and otherwise by a fragment of the
  # resource's SEEK URI.
  def property_values(crate, resource, prefix)
    extended_metadata = resource.extended_metadata
    return [] if extended_metadata.blank?

    attributes = extended_metadata.extended_metadata_type.extended_metadata_attributes.index_by(&:title)
    extended_metadata.data.filter_map do |key, value|
      next if value.blank?

      attribute = attributes[key.to_s]
      add_property_value(crate, "##{prefix}-#{key.to_s.parameterize}", property_name(attribute, key),
                         property_id(attribute, resource, key), value)
    end
  end

  def add_property_value(crate, id, name, property_id, value)
    contextual(crate, id, 'PropertyValue', 'name' => name, 'propertyID' => property_id, 'value' => value).reference
  end

  def property_name(attribute, key)
    return key.to_s.humanize unless attribute

    attribute.label.presence || attribute.title
  end

  def property_id(attribute, resource, key)
    attribute&.pid.presence || "#{resource.rdf_seek_id}#extended_metadata/#{key}"
  end

  def create_fairdata_test_case_types
    FactoryBot.create(:fairdata_test_case_investigation_extended_metadata)
    FactoryBot.create(:fairdata_test_case_study_extended_metadata)
    FactoryBot.create(:fairdata_test_case_obsv_unit_extended_metadata)
    FactoryBot.create(:fairdata_test_case_assay_extended_metadata)
    FactoryBot.create(:fairdatastation_test_case_sample_type)
    FactoryBot.create(:experimental_assay_class)
  end

  def setup_test_case_investigation
    create_fairdata_test_case_types
    contributor = FactoryBot.create(:person)
    policy = FactoryBot.create(:public_policy)
    path = "#{Rails.root}/test/fixtures/files/fair_data_station/seek-fair-data-station-test-case.ttl"
    inv = Seek::FairDataStation::Reader.new.parse_graph(path).first
    investigation = Seek::FairDataStation::Writer.new.construct_isa(inv, contributor, contributor.projects, policy)
    assert_difference('Investigation.count', 1) { investigation.save! }
    assert_equal 'seek-test-investigation', investigation.external_identifier
    investigation
  end
end
