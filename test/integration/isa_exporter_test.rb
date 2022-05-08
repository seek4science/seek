require 'test_helper'
require 'json'
require 'json-schema'

class IsaExporterTest < ActionDispatch::IntegrationTest
	fixtures :all
	include SharingFormTestHelper

	def setup
		before_all
	end

	@@before_all_run = false

	def before_all
		return if @@before_all_run
		@@before_all_run = true

		@project = Factory(:project)
		User.current_user = Factory(:user, login: 'test')
		post '/session', params: { login: 'test', password: generate_user_password }
		@current_user = User.current_user
		@current_user.person.add_to_project_and_institution(@project, @current_user.person.institutions.first)
		@investigation = Factory(:investigation, projects: [@project], contributor: @current_user.person)
		create_basic_isa_project
		with_config_value(:project_single_page_enabled, true) do
			get "/single_pages/#{@project.id}/export_isa?investigation_id=#{@investigation.id}"
		end
		@@response = response
	end

	# 30 rules of ISA: https://isa-specs.readthedocs.io/en/latest/isajson.html#content-rules

	# 1
	test 'Files SHOULD be encoded using UTF-8' do
		assert_equal @@response.body.encoding.name, 'UTF-8'
	end

	# 2
	test 'ISA-JSON content MUST be well-formed JSON' do
		assert valid_json?(@@response.body)
	end

	# 3
	test 'ISA-JSON content MUST validate against the ISA-JSON schemas' do
		investigation = JSON.parse(@@response.body)['investigation']
		valid_isa_json?(JSON.generate(investigation))
	end

	# 4
	test 'ISA-JSON files SHOULD be suffixed with a .json extension' do
		assert @@response['Content-Disposition'].include? '.json'
	end

	# 5
	test 'Dates SHOULD be supplied in the ISO8601 format “YYYY-MM-DD”' do
		# gather all date key-value pairs
		values = []
		json = JSON.parse(@@response.body)
		investigation = json['investigation']
		studies = investigation['studies']
		values << nested_hash_value(investigation, 'submissionDate')
		values << nested_hash_value(investigation, 'publicReleaseDate')
		studies.each do |s|
			values << nested_hash_value(s, 'submissionDate')
			values << nested_hash_value(s, 'publicReleaseDate')
			s['processSequence'].each { |p| values << nested_hash_value(p, 'date') }
			s['assays'].each { |a| a['processSequence'].each { |p| values << nested_hash_value(p, 'date') } }
		end
		values.each { |v| assert v == '' || valid_date?(v) }
	end

	# 8
	test 'Characteristic Categories declared should be referenced by at least one Characteristic' do
		characteristics, categories = [], []
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		studies.each do |s|
			categories += s['characteristicCategories']
			sources = s['materials']['sources']
			samples = s['materials']['samples']
			sources.each { |m| characteristics += m['characteristics'] }
			samples.each { |m| characteristics += m['characteristics'] }
			s['assays'].each do |a|
				a['materials']['otherMaterials'].each { |o| characteristics += o['characteristics'] }
				categories += a['characteristicCategories']
			end
		end
		characteristics = characteristics.map { |c| c['category']['@id'] }
		categories = categories.map { |c| c['@id'] }

		categories.each { |c| assert characteristics.include?(c) }

		# 9 'Characteristics must reference a Characteristic Category declaration'
		characteristics.each { |c| assert categories.include?(c) }
	end

	# 10
	test 'Unit Categories declared should be referenced by at least one Unit' do
		# Not implemented
	end

	# 11
	test 'Units must reference a Unit Category declaration.' do
		# Not implemented
	end

	# 12
	test 'All Sources and Samples must be declared in the Study-level materials section' do
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		materials = studies.map { |s| s['materials']['sources'] + s['materials']['samples'] }
		materials = materials.flatten.map { |so| so['@id'] }

		all_sources_and_samples = @@source.samples.map { |s| "#source/#{s.id}" }
		all_sources_and_samples += @@sample_collection.samples.map { |s| "#sample/#{s.id}" }

		all_sources_and_samples.each { |s| assert materials.include?(s) }
	end

	# 13
	test 'All other materials and DataFiles must be declared in the Assay-level material and data sections respectively' do
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		other_materials = []
		studies.each do |s|
			s['assays'].each do |a|
				other_materials += a['materials']['otherMaterials'].map { |so| so['@id'] }
				other_materials += a['dataFiles'].map { |so| so['@id'] }
			end
		end

		# Collect all samples with tag=data_file and tag=other_material
		assay_level_types = [@@assay_sample_type]
		m =
			assay_level_types
				.select { |s| s.sample_attributes.detect { |sa| sa.isa_tag&.isa_other_material? } }
				.map { |s| s.samples.map { |sample| "#other_material/#{sample.id}" } }
		d =
			assay_level_types
				.select { |s| s.sample_attributes.detect { |sa| sa.isa_tag&.isa_data_file? } }
				.map { |s| s.samples.map { |sample| "#other_material/#{sample.id}" } }
		(m + d).flatten.each { |s| assert other_materials.include?(s) }
	end

	# 14
	test 'Each Process in a Process Sequence MUST link with other Processes forwards or backwards, unless it is a starting or terminating Process' do
		# study > processSequence > previousProcess/nextProcess is always empty, since there is one process always
		# assay > processSequence >
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		studies.each do |s|
			assays_count = s['assays'].length
			s['assays'].each_with_index do |a, i|
				a['processSequence'].each { |p| assert p['previousProcess'].present? }

				a['processSequence'].each do |p|
					assert (i == assays_count - 1) ? p['nextProcess'].blank? : p['nextProcess'].present?
				end
			end
		end
	end

	# 15
	test 'Protocols declared SHOULD be referenced by at least one Protocol REF' do
		# Protocol REF is appeared in study > processSequence and study > assya > processSequence
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
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

	# 17
	test 'Study Factors declared SHOULD be referenced by at least one Factor Value' do
		# Not implemented
	end

	# 18
	test 'Factor Values MUST reference a Study Factor declared in the Study-level factors section' do
		# Not implemented
	end

	# 21
	test 'Study Factors SHOULD have a name' do
		# Not implemented
	end

	# 22
	test 'Sources and Samples declared SHOULD be referenced by at least one Process at the Study-level' do
		# sources and samples should be referenced in study > processSequence > inputs/outputs
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
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
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
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
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		studies.each do |s|
			assert s['filename'].present?
			s['assays'].each { |a| assert a['filename'].present? }
		end
	end

	# 25
	test 'Ontology Source References declared SHOULD be referenced by at least one Ontology Annotation' do
		json = JSON.parse(@@response.body)
		studies = json['investigation']['studies']
		ontology_refs = json['investigation']['ontologySourceReferences']

		ontologies = []
		ontologies += json['investigation']['people'].map { |p| p['roles'] }
		studies.each do |s|
			ontologies += s['people'].map { |p| p['roles'] }
			ontologies += s['characteristicCategories'].map { |c| c['characteristicType'] }
			ontologies += s['materials']['sources'].map { |s| s['characteristics'].map { |c| c['value'] } }
			ontologies += s['materials']['samples'].map { |s| s['characteristics'].map { |c| c['value'] } }
			ontologies += s['protocols'].map { |p| p['protocolType'] }
			ontologies += s['protocols'].map { |p| p['parameters'].map { |pa| pa['parameterName'] } }
			ontologies += s['protocols'].map { |p| p['components'].map { |c| c['componentType'] } }
			ontologies += s['processSequence'].map { |p| p['parameterValues'].map { |c| c['value'] } }

			s['assays'].each do |a|
				ontologies << a['measurementType']
				ontologies << a['technologyType']
				ontologies += a['characteristicCategories'].map { |c| c['characteristicType'] }
				ontologies += a['materials']['otherMaterials'].map { |o| o['characteristics'].map { |c| c['value'] } }
			end
		end

		ontologies = ontologies.flatten.map { |o| o['termSource'] }.uniq.reject { |c| c.empty? }

		# 27 'Ontology Source References MUST contain a Term Source Name'
		ontology_refs.each { |ref| assert ref['name'].present? }

		ontology_refs = ontology_refs.map { |o| o['name'] }.uniq

		ontology_refs.each { |p| assert ontologies.include?(p) }

		# 26 'Ontology Annotations MUST reference a Ontology Source Reference declaration'
		ontologies.each { |p| assert ontology_refs.include?(p) }
	end

	# 28
	test 'Ontology Annotations with a term and/or accession MUST provide a Term Source REF pointing to a declared Ontology Source Reference' do
		# Conflict
	end

	# 29
	test 'Publication metadata SHOULD match that of publication record in PubMed corresponding to the provided PubMed ID.' do
		# Not implemented
	end

	# # 30
	# test 'Comments MUST have a name' do
	# 	all_comments = []
	# 	all_comments.each { |c| assert c.key?('name') }
	# end
end

private

def nested_hash_value(obj, key)
	if obj.respond_to?(:key?) && obj.key?(key)
		obj[key]
	elsif obj.respond_to?(:each)
		r = nil
		obj.find { |*a| r = nested_hash_value(a.last, key) }
		r
	end
end

def valid_json?(json)
	begin
		JSON.parse(json)
		return true
	rescue Exception => e
		return false
	end
end

def valid_isa_json?(json)
	definitions_path =
		File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'isa_schemas', 'investigation_schema.json')
	if File.readable?(definitions_path)
		errors = JSON::Validator.fully_validate_json(definitions_path, json)
		unless errors.empty?
			msg = ''
			errors.each { |e| msg += e + "\n" }
			raise Minitest::Assertion, msg
		end
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
	# Create ontologies
	ontologies = create_ontologies

	controlled_vocab_attribute_type = Factory(:controlled_vocab_attribute_type)
	ontology_attribute_type = Factory(:controlled_vocab_attribute_type, title: 'Ontology')
	sample_multi_sample_attribute_type = Factory(:sample_multi_sample_attribute_type)
	string_sample_attribute_type = Factory(:string_sample_attribute_type)

	# Create ISA Study
	source =
		SampleType.new title: 'ISA Source',
		               project_ids: [@project.id],
		               isa_template: Template.find_by_title('ISA Source'),
		               contributor: @current_user.person
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Name',
			is_title: true,
			required: true,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 1',
			required: true,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	source_characteristic_2_CV = Factory(:apples_sample_controlled_vocab)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 2',
			required: true,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: source_characteristic_2_CV.id
		)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 3',
			required: false,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: ontology_attribute_type,
			sample_controlled_vocab_id: ontologies[0].id
		)
	source.save!

	sample_collection =
		SampleType.new title: 'ISA sample collection',
		               project_ids: [@project.id],
		               isa_template: Template.find_by_title('ISA sample collection'),
		               contributor: @current_user.person
	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Input',
			required: true,
			sample_type: sample_collection,
			linked_sample_type_id: source.id,
			sample_attribute_type: sample_multi_sample_attribute_type
		)
	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('protocol')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 1',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: string_sample_attribute_type
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 2',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 3',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: ontology_attribute_type,
			sample_controlled_vocab_id: ontologies[0].id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Sample Name',
			required: true,
			is_title: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample')&.id,
			sample_attribute_type: string_sample_attribute_type
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 1',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: string_sample_attribute_type
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 2',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 3',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: ontology_attribute_type,
			sample_controlled_vocab_id: ontologies[1].id
		)

	sample_collection.save!

	study =
		Factory(
			:study,
			investigation: @investigation,
			sample_types: [source, sample_collection],
			sop: Factory(:sop, policy: Factory(:public_policy)),
			contributor: @current_user.person
		)

	# Create ISA Assay

	assay_sample_type =
		SampleType.new title: 'ISA Assay 1',
		               project_ids: [@project.id],
		               isa_template: Template.find_by_title('ISA Assay 1'),
		               contributor: @current_user.person
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Input',
			required: true,
			sample_type: assay_sample_type,
			linked_sample_type_id: sample_collection.id,
			sample_attribute_type: sample_multi_sample_attribute_type
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Protocol Assay 1',
			required: true,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('protocol')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 1',
			required: true,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 2',
			required: false,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 3',
			required: false,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: ontologies[0].id
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Extract Name',
			is_title: true,
			required: true,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 1',
			required: true,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: string_sample_attribute_type
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 2',
			required: false,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)
	assay_sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 3',
			required: false,
			sample_type: assay_sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: controlled_vocab_attribute_type,
			sample_controlled_vocab_id: ontologies[1].id
		)
	assay_sample_type.save!

	assay =
		Factory(
			:assay,
			study: study,
			sample_type: assay_sample_type,
			sop_ids: [Factory(:sop, policy: Factory(:public_policy)).id],
			contributor: @current_user.person,
			position: 0
		)

	@@source = source
	@@sample_collection = sample_collection
	@@assay_sample_type = assay_sample_type

	# Create samples
	sample_1 =
		Factory :sample,
		        title: 'sample_1',
		        sample_type: source,
		        project_ids: [@project.id],
		        data: {
				'Source Name': 'Source Name',
				'Source Characteristic 1': 'Source Characteristic 1',
				'Source Characteristic 2': source_characteristic_2_CV.sample_controlled_vocab_terms.first.label
		        }

	sample_2 =
		Factory :sample,
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

	sample_3 =
		Factory :sample,
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
end

def create_ontologies
	ontology1 =
		SampleControlledVocab.new(
			{ title: 'organism part', source_ontology: 'efo', ols_root_term_uri: 'http://www.ebi.ac.uk/efo/EFO_0000635' }
		)
	ontology1.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'anatomical entity' })
	ontology1.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'retroperitoneal space' })
	ontology1.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'abdominal cavity' })

	ontology2 =
		SampleControlledVocab.new(
			{
				title: 'sample material processing',
				source_ontology: 'OBI',
				ols_root_term_uri: 'http://purl.obolibrary.org/obo/OBI_0000094'
			}
		)
	ontology2.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'dissection' })
	ontology2.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'enzymatic cleavage' })
	ontology2.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'non specific enzymatic cleavage' })
	ontology2.sample_controlled_vocab_terms << SampleControlledVocabTerm.new({ label: 'protease cleavage' })
	ontology2.sample_controlled_vocab_terms <<
		SampleControlledVocabTerm.new({ label: 'DNA restriction enzyme digestion' })

	ontology1.save!
	ontology2.save!

	[ontology1, ontology2]
end
