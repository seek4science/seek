require 'test_helper'
require 'json'
require 'json-schema'

class IsaExporterTest < ActionDispatch::IntegrationTest
	fixtures :all
	include SharingFormTestHelper

	def setup
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
		@response = response.body
	end

	test 'exported ISA-JSON should be encoded using UTF-8' do
		assert_equal @response.encoding.name, 'UTF-8'
	end

	test 'exported ISA-JSON content must be well-formed JSON' do
		assert valid_json?(@response)
	end

	test 'exported ISA-JSON content must validate against the ISA-JSON schemas' do
		investigation = JSON.parse(@response)['investigation']
		valid_isa_json?(JSON.generate(investigation))
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
	p json
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

def create_basic_isa_project
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
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 1',
			required: true,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	source_characteristic_2_CV = Factory(:apples_sample_controlled_vocab)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 2',
			required: true,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: source_characteristic_2_CV.id
		)
	source.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Source Characteristic 3',
			required: false,
			sample_type: source,
			isa_tag_id: IsaTag.find_by_title('source_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:ontology_sample_controlled_vocab).id
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
			sample_attribute_type: Factory(:sample_multi_sample_attribute_type)
		)
	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('protocol')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 1',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 2',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample collection parameter value 3',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:ontology_sample_controlled_vocab).id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Sample Name',
			required: true,
			is_title: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 1',
			required: true,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 2',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	sample_collection.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'sample characteristic 3',
			required: false,
			sample_type: sample_collection,
			isa_tag_id: IsaTag.find_by_title('sample_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:ontology_sample_controlled_vocab).id
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

	sample_type =
		SampleType.new title: 'ISA Assay 1',
		               project_ids: [@project.id],
		               isa_template: Template.find_by_title('ISA Assay 1'),
		               contributor: @current_user.person
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Input',
			required: true,
			sample_type: sample_type,
			linked_sample_type_id: sample_collection.id,
			sample_attribute_type: Factory(:sample_multi_sample_attribute_type)
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Protocol Assay 1',
			required: true,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('protocol')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 1',
			required: true,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 2',
			required: false,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)

	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'Assay 1 parameter value 3',
			required: false,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('parameter_value')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:ontology_sample_controlled_vocab).id
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material 1',
			is_title: true,
			required: true,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 1',
			required: true,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: Factory(:string_sample_attribute_type)
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 2',
			required: false,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:apples_sample_controlled_vocab).id
		)
	sample_type.sample_attributes <<
		Factory(
			:sample_attribute,
			title: 'other material characteristic 3',
			required: false,
			sample_type: sample_type,
			isa_tag_id: IsaTag.find_by_title('other_material_characteristic')&.id,
			sample_attribute_type: Factory(:controlled_vocab_attribute_type),
			sample_controlled_vocab_id: Factory(:ontology_sample_controlled_vocab).id
		)
	sample_type.save!

	assay =
		Factory(
			:assay,
			study: study,
			sample_type: sample_type,
			sop_ids: [Factory(:sop, policy: Factory(:public_policy)).id],
			contributor: @current_user.person,
			position: 0
		)

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
		        sample_type: sample_type,
		        project_ids: [@project.id],
		        data: {
				Input: [sample_2.id],
				'Protocol Assay 1': 'Protocol Assay 1',
				'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
				'other material 1': 'other material 1',
				'other material characteristic 1': 'other material characteristic 1'
		        }
end
