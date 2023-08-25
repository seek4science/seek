require 'test_helper'

class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :isa_tags, :templates

  def setup
    @instance_name = Seek::Config::instance_name
    @member = FactoryBot.create :user
    login_as @member
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      project = FactoryBot.create(:project)
      get :show, params: { id: project.id }
      assert_response :success
    end
  end

  test 'should hide inaccessible items in treeview' do
    project = FactoryBot.create(:project)
    FactoryBot.create(:investigation, contributor: @member.person, policy: FactoryBot.create(:private_policy),
                            projects: [project])

    login_as(FactoryBot.create(:user))
    inv_two = FactoryBot.create(:investigation, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy),
                                      projects: [project])

    controller = TreeviewBuilder.new project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    assert_equal 'hidden item', json['children'][0]['text']
    assert_equal inv_two.title, json['children'][1]['text']
  end

  test 'should not export isa from unauthorized investigation' do
    with_config_value(:project_single_page_enabled, true) do
      project = FactoryBot.create(:project)
      investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy), projects: [project])
      get :export_isa, params: { id: project.id, investigation_id: investigation.id }
      assert_equal flash[:error], 'The investigation cannot be found!'
      assert_redirected_to action: :show
    end
  end

  test 'generates a valid export of sources in single page' do
    with_config_value(:project_single_page_enabled, true) do
      # Generate the excel data
      person = @member.person
      project = FactoryBot.create(:project)
      study = FactoryBot.create(:study)
      id_label = "#{Seek::Config::instance_name} id"

      source_sample_type = FactoryBot.create(:isa_source_sample_type,
                                             contributor: person,
                                             project_ids: [project.id],
                                             isa_template: Template.find_by_title('ISA Source'),
                                             studies: [study])

      sources = (1..5).map do |n|
        FactoryBot.create(
          :sample,
          title: "source#{n}",
          sample_type: source_sample_type,
          project_ids: [project.id],
          contributor: person,
          data: {
            'Source Name': 'Source Name',
            'Source Characteristic 1': 'Source Characteristic 1',
            'Source Characteristic 2':
              source_sample_type
                .sample_attributes
                .find_by_title('Source Characteristic 2')
                .sample_controlled_vocab
                .sample_controlled_vocab_terms
                .first
                .label
          }
        )
      end

      source_ids = sources.map { |s| { id_label => s.id } }
      sample_type_id = source_sample_type.id
      study_id = study.id
      assay_id = nil

      post_params = { sample_data: source_ids.to_json,
                      sample_type_id: sample_type_id.to_json,
                      study_id: study_id.to_json,
                      assay_id: assay_id.to_json }

      post :export_to_excel, params: post_params, xhr: true

      assert_response :ok, msg = "Couldn't reach the server"

      response_body = JSON.parse(response.body)
      assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
      cache_uuid = response_body['uuid']

      get :download_samples_excel, params: { uuid: cache_uuid }
      assert_response :ok, msg = 'Unable to generate the excel'
    end
  end

  test 'generates a valid export of source samples in single page' do
    with_config_value(:project_single_page_enabled, true) do
      person = @member.person
      project = FactoryBot.create(:project)
      study = FactoryBot.create(:study)
      assay = FactoryBot.create(:assay)
      id_label = "#{Seek::Config::instance_name} id"

      source_sample_type = FactoryBot.create(:isa_source_sample_type,
                                             contributor: person,
                                             project_ids: [project.id],
                                             isa_template: Template.find_by_title('ISA Source'),
                                             studies: [study])

      sample_collection_sample_type = FactoryBot.create(:isa_sample_collection_sample_type,
                                                        contributor: person,
                                                        project_ids: [project.id],
                                                        isa_template: Template.find_by_title('ISA sample collection'),
                                                        studies: [study],
                                                        linked_sample_type: source_sample_type)

      sources = (1..5).map do |n|
        FactoryBot.create(
          :sample,
          title: "source #{n}",
          sample_type: source_sample_type,
          project_ids: [project.id],
          contributor: person,
          data: {
            'Source Name': 'Source Name',
            'Source Characteristic 1': 'Source Characteristic 1',
            'Source Characteristic 2':
              source_sample_type
                .sample_attributes
                .find_by_title('Source Characteristic 2')
                .sample_controlled_vocab
                .sample_controlled_vocab_terms
                .first
                .label
          }
        )
      end

      source_samples = (1..4).map do |n|
        FactoryBot.create(
          :sample,
          title: "Sample collection #{n}",
          sample_type: sample_collection_sample_type,
          project_ids: [project.id],
          contributor: person,
          data: {
            Input: [sources[n - 1].id, sources[n].id],
            'sample collection': 'sample collection',
            'sample collection parameter value 1': 'sample collection parameter value 1',
            'Sample Name': 'sample name',
            'sample characteristic 1': 'sample characteristic 1'
          }
        )
      end

      source_sample_ids = source_samples.map { |ss| { id_label => ss.id } }
      sample_type_id = sample_collection_sample_type.id
      study_id = study.id
      assay_id = assay.id

      post_params = { sample_data: source_sample_ids.to_json,
                      sample_type_id: sample_type_id.to_json,
                      study_id: study_id.to_json,
                      assay_id: assay_id.to_json }

      post :export_to_excel, params: post_params, xhr: true

      assert_response :ok, msg = "Couldn't reach the server"

      response_body = JSON.parse(response.body)
      assert response_body.key?("uuid"), msg = "Response body is expected to have a 'uuid' key"
      cache_uuid = response_body["uuid"]

      get :download_samples_excel, params: { uuid: cache_uuid }
      assert_response :ok, msg = 'Unable to generate the excel'
    end
  end
end
