require 'test_helper'
require 'json'
require 'json-schema'

class IsaExporterTest < ActionDispatch::IntegrationTest
  fixtures :all
  include SharingFormTestHelper

  def self.store
    @store ||= yield
  end

  def setup
    before_all.each do |var, value|
      instance_variable_set("@#{var}", value)
    end
  end

  def before_all
    self.class.store do
      @project = FactoryBot.create(:project)
      User.current_user = FactoryBot.create(:user, login: 'test')
      post '/session', params: { login: 'test', password: generate_user_password }
      @current_user = User.current_user
      @current_user.person.add_to_project_and_institution(@project, @current_user.person.institutions.first)
      @investigation = FactoryBot.create(:investigation, projects: [@project], contributor: @current_user.person)
      isa_project_vars = create_basic_isa_project
      with_config_value(:project_single_page_enabled, true) do
        get export_isa_single_page_path(@project.id, investigation_id: @investigation.id)
      end

      isa_project_vars.merge(
        project: @project,
        investigation: @investigation,
        current_user: @current_user,
        response: @response,
        json: JSON.parse(@response.body))
    end
  end

  # 30 rules of ISA: https://isa-specs.readthedocs.io/en/latest/isajson.html#content-rules

  # 1
  test 'Files SHOULD be encoded using UTF-8' do
    assert_equal @response.body.encoding.name, 'UTF-8'
  end

  # 2
  test 'ISA-JSON content MUST be well-formed JSON' do
    assert valid_json?(@response.body)
  end

  # 3
  test 'ISA-JSON content MUST validate against the ISA-JSON schemas' do
    investigation = @json
    valid_isa_json?(JSON.generate(investigation))
  end

  # 4
  test 'ISA-JSON files SHOULD be suffixed with a .json extension' do
    assert @response['Content-Disposition'].include? '.json'
  end

  # 5
  test 'Dates SHOULD be supplied in the ISO8601 format “YYYY-MM-DD”' do
    # gather all date key-value pairs
    investigation = @json
    values = nested_hash_value(investigation, 'submissionDate')
    values += nested_hash_value(investigation, 'publicReleaseDate')
    values += nested_hash_value(investigation, 'date')
    values.each { |v| assert v == '' || valid_date?(v) }
  end

  # 8
  test 'Characteristic Categories declared should be referenced by at least one Characteristic' do
    studies = @json['studies']
    characteristics = nested_hash_value(studies, 'characteristics').flatten
    categories = nested_hash_value(studies, 'characteristicCategories').flatten

    characteristics = characteristics.map { |c| c['category']['@id'] }
    categories = categories.map { |c| c['@id'] }

    categories.each { |c| assert characteristics.include?(c) }

    # 9 'Characteristics must reference a Characteristic Category declaration'
    characteristics.each { |c| assert categories.include?(c) }
  end

  # # 10
  # test 'Unit Categories declared should be referenced by at least one Unit' do
  #   # Not implemented
  # end

  # # 11
  # test 'Units must reference a Unit Category declaration.' do
  #   # Not implemented
  # end

  # 12
  test 'All Sources and Samples must be declared in the Study-level materials section' do
    studies = @json['studies']
    materials = studies.map { |s| s['materials']['sources'] + s['materials']['samples'] }
    materials = materials.flatten.map { |so| so['@id'] }

    all_sources_and_samples = @source.samples.map { |s| "#source/#{s.id}" }
    all_sources_and_samples += @sample_collection.samples.map { |s| "#sample/#{s.id}" }

    all_sources_and_samples.each { |s| assert materials.include?(s) }
  end

  # 13
  test 'All other materials and DataFiles must be declared in the Assay-level material and data sections respectively' do
    studies = @json['studies']
    other_materials = []
    studies.each do |s|
      s['assays'].each do |a|
        other_materials += a['materials']['otherMaterials'].map { |so| so['@id'] }
        other_materials += a['dataFiles'].map { |so| so['@id'] }
      end
    end

    # Collect all samples with tag=data_file and tag=other_material
    assay_level_types = [@assay_sample_type]
    m = assay_level_types.select { |s| s.sample_attributes.detect { |sa| sa.isa_tag&.isa_other_material? } }
    m = m.map { |s| s.samples.map { |sample| "#other_material/#{sample.id}" } }
    d = assay_level_types.select { |s| s.sample_attributes.detect { |sa| sa.isa_tag&.isa_data_file? } }
    d = d.map { |s| s.samples.map { |sample| "#other_material/#{sample.id}" } }
    (m + d).flatten.each { |s| assert other_materials.include?(s) }
  end

  # 14
  test 'Each Process in a Process Sequence MUST link with other Processes forwards or backwards, unless it is a starting or terminating Process' do
    # study > processSequence > previousProcess/nextProcess is always empty, since there is one process always
    # assay > processSequence >
    studies = @json['studies']
    studies.each do |s|
      assays_count = s['assays'].length
      s['assays'].each_with_index do |a, i|
        a['processSequence'].each do |p|
          assert p['previousProcess'].present?
          assert i == assays_count - 1 ? p['nextProcess'].blank? : p['nextProcess'].present?
        end
      end
    end
  end

  # 15
  test 'Protocols declared SHOULD be referenced by at least one Protocol REF' do
    # Protocol REF is appeared in study > processSequence and study > assya > processSequence
    studies = @json['studies']
    protocols, protocol_refs = [], []
    studies.each do |s|
      protocols =
        s['protocols'].map do |pr|
          # 19 'Protocols SHOULD have a name'
          assert pr['name'].present?

          # 20 'Protocol Parameters SHOULD have a name'
          pr['parameters'].each { |pp| assert pp['parameterName'].present? }
          return pr['@id']
        end
      protocol_refs = s['processSequence'].map { |p| p['executesProtocol']['@id'] }
      s['assays'].each { |a| protocol_refs += a['processSequence'].map { |p| p['executesProtocol']['@id'] } }
    end

    protocols.each { |p| assert protocol_refs.include?(p) }

    # 16 'Protocol REFs MUST reference a Protocol declaration'
    protocol_refs.each { |p| assert protocols.include?(p) }
  end

  # # 17
  # test 'Study Factors declared SHOULD be referenced by at least one Factor Value' do
  #   # Not implemented
  # end

  # # 18
  # test 'Factor Values MUST reference a Study Factor declared in the Study-level factors section' do
  #   # Not implemented
  # end

  # # 21
  # test 'Study Factors SHOULD have a name' do
  #   # Not implemented
  # end

  # 22
  test 'Sources and Samples declared SHOULD be referenced by at least one Process at the Study-level' do
    # sources and samples should be referenced in study > processSequence > inputs/outputs
    studies = @json['studies']
    materials, processes = [], []
    studies.each do |s|
      materials += s['materials']['sources'] + s['materials']['samples']
      processes += s['processSequence'].map { |p| p['inputs'] + p['outputs'] }
    end
    materials = materials.map { |so| so['@id'] }
    processes = processes.flatten.map { |p| p['@id'] }
    materials.each { |p| assert processes.include?(p) }
  end

  # 23
  test 'Samples, other materials, and DataFiles declared SHOULD be used in at least one Process at the Assay-level.' do
    studies = @json['studies']
    studies.each do |s|
      s['assays'].each do |a|
        other_materials = a['materials']['samples'] + a['materials']['otherMaterials'] + a['dataFiles']
        other_materials = other_materials.map { |m| m['@id'] }
        processes = a['processSequence'].map { |p| p['inputs'] + p['outputs'] }
        processes = processes.flatten.map { |p| p['@id'] }

        other_materials.each { |p| assert processes.include?(p) }
      end
    end
  end

  # 24
  test 'Study and Assay filenames SHOULD be present' do
    studies = @json['studies']
    studies.each do |s|
      assert s['filename'].present?
      s['assays'].each { |a| assert a['filename'].present? }
    end
  end

  # 25
  test 'Ontology Source References declared SHOULD be referenced by at least one Ontology Annotation' do
    investigation = @json
    ontology_refs = investigation['ontologySourceReferences']

    ontologies = nested_hash_value(investigation, 'termSource')
    ontologies = ontologies.uniq.reject(&:empty?)

    # 27 'Ontology Source References MUST contain a Term Source Name'
    ontology_refs.each { |ref| assert ref['name'].present? }

    ontology_refs = ontology_refs.map { |o| o['name'] }.uniq

    ontology_refs.each { |p| assert ontologies.include?(p) }

    # 26 'Ontology Annotations MUST reference a Ontology Source Reference declaration'
    ontologies.each { |p| assert ontology_refs.include?(p) }
  end

  # # 28
  # test 'Ontology Annotations with a term and/or accession MUST provide a Term Source REF pointing to a declared Ontology Source Reference' do
  #   # Conflict
  # end

  # # 29
  # test 'Publication metadata SHOULD match that of publication record in PubMed corresponding to the provided PubMed ID.' do
  #   # Not implemented
  # end

  # # 30
  # test 'Comments MUST have a name' do
  # Not implemented
  # end

  private

  def nested_hash_value(obj, key, ans = [])
    if obj.respond_to?(:keys)
      ans << obj[key] if obj.key?(key)
      obj.each_key { |k| nested_hash_value(obj[k], key, ans) }
    elsif obj.respond_to?(:each)
      obj.each { |o| nested_hash_value(o, key, ans) }
    end
    ans
  end

  def valid_json?(json)
    begin
      JSON.parse(json)
      return true
    rescue JSON::ParserError
      false
    end
  end

  def valid_isa_json?(json)
    definitions_path =
      File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'isa_schemas', 'investigation_schema.json')
    if File.readable?(definitions_path)
      errors = JSON::Validator.fully_validate_json(definitions_path, json)
      raise Minitest::Assertion, errors.join("\n") unless errors.empty?
    end
  end

  def valid_date?(date)
    # '2016-09-18T17:34:02.666Z'
    Date.iso8601(date.to_s)
    return true
  rescue ArgumentError
    false
  end

  def create_basic_isa_project
    person = FactoryBot.create(:person, project: @project)

    source =
      FactoryBot.create(
        :isa_source_sample_type,
        contributor: person,
        project_ids: [@project.id],
        isa_template: Template.find_by_title('ISA Source')
      )
    sample_collection =
      FactoryBot.create(
        :isa_sample_collection_sample_type,
        contributor: person,
        project_ids: [@project.id],
        isa_template: Template.find_by_title('ISA sample collection'),
        linked_sample_type: source
      )
    assay_sample_type =
      FactoryBot.create(
        :isa_assay_sample_type,
        contributor: person,
        project_ids: [@project.id],
        isa_template: Template.find_by_title('ISA Assay 1'),
        linked_sample_type: sample_collection
      )

    study =
      FactoryBot.create(
        :study,
        investigation: @investigation,
        sample_types: [source, sample_collection],
        sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))]
      )

    FactoryBot.create(
      :assay,
      study: study,
      sample_type: assay_sample_type,
      sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
      contributor: @current_user.person,
      position: 0
    )

    # Create samples
    sample_1 =
      FactoryBot.create :sample,
              title: 'sample_1',
              sample_type: source,
              project_ids: [@project.id],
              data: {
                'Source Name': 'Source Name',
                'Source Characteristic 1': 'Source Characteristic 1',
                'Source Characteristic 2':
                  source
                    .sample_attributes
                    .find_by_title('Source Characteristic 2')
                    .sample_controlled_vocab
                    .sample_controlled_vocab_terms
                    .first
                    .label
              }

    sample_2 =
      FactoryBot.create :sample,
              title: 'sample_2',
              sample_type: sample_collection,
              project_ids: [@project.id],
              data: {
                Input: [sample_1.id],
                'sample collection': 'sample collection',
                'sample collection parameter value 1': 'sample collection parameter value 1',
                'Sample Name': 'sample name',
                'sample characteristic 1': 'sample characteristic 1'
              }

    FactoryBot.create :sample,
            title: 'sample_2',
            sample_type: assay_sample_type,
            project_ids: [@project.id],
            data: {
              Input: [sample_2.id],
              'Protocol Assay 1': 'Protocol Assay 1',
              'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
              'Extract Name': 'Extract Name',
              'other material characteristic 1': 'other material characteristic 1'
            }

    { source: source,
      sample_collection: sample_collection,
      assay_sample_type: assay_sample_type }
  end
end
