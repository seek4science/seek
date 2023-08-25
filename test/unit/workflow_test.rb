require 'test_helper'
require 'minitest/mock'

class WorkflowTest < ActiveSupport::TestCase
  test 'validations' do
    workflow = FactoryBot.create :workflow
    workflow.title = ''

    assert !workflow.valid?

    workflow.reload
  end

  test "new workflow's version is 1" do
    workflow = FactoryBot.create :workflow
    assert_equal 1, workflow.version
  end

  test 'can create new version of workflow' do
    workflow = FactoryBot.create :workflow
    old_attrs = workflow.attributes

    disable_authorization_checks do
      workflow.save_as_new_version('new version')
    end

    assert_equal 1, old_attrs['version']
    assert_equal 2, workflow.version

    old_attrs.delete('version')
    new_attrs = workflow.attributes
    new_attrs.delete('version')

    old_attrs.delete('updated_at')
    new_attrs.delete('updated_at')

    old_attrs.delete('created_at')
    new_attrs.delete('created_at')

    assert_equal old_attrs, new_attrs
  end

  test 'sop association' do
    workflow = FactoryBot.create :workflow
    assert workflow.sops.empty?

    User.with_current_user(workflow.contributor.user) do
      assert_difference 'workflow.sops.count' do
        workflow.sops << FactoryBot.create(:sop, contributor:workflow.contributor)
      end
    end
  end

  test 'has uuid' do
    workflow = FactoryBot.create :workflow
    assert_not_nil workflow.uuid
  end

  test 'generates fresh RO-Crate for individual workflow' do
    workflow = FactoryBot.create(:cwl_workflow, license: 'MIT', other_creators: 'Jane Smith, John Smith')
    creator = FactoryBot.create(:person)
    workflow.creators << creator
    assert workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert crate.main_workflow
    assert crate.main_workflow_diagram
    refute crate.main_workflow_cwl
    assert_equal 'Common Workflow Language', crate.main_workflow.programming_language['name']

    assert_equal Seek::License.find('MIT')&.url, crate.main_workflow['license']

    # authors = crate.main_workflow['creator'].map(&:name)
    # assert_includes authors, 'John Smith'
    # assert_includes authors, 'Jane Smith'
    # assert crate.author.detect { |a| a['identifier'] == URI.join(Seek::Config.site_base_host, "people/#{creator.id}").to_s }
    assert_equal Seek::Util.routes.project_url(workflow.projects.first.id),
                 crate.main_workflow['producer']['@id']
  end

  test 'generates fresh RO-Crate for workflow/diagram/abstract workflow' do
    workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, other_creators: 'Jane Smith, John Smith')
    assert workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert crate.main_workflow
    assert crate.main_workflow_diagram
    assert crate.main_workflow_cwl

    assert_equal 'Galaxy', crate.main_workflow.programming_language['name']
    assert_equal 'Common Workflow Language', crate.main_workflow_cwl.programming_language['name']
  end

  test 'serves existing RO-Crate for RO-Crate workflow' do
    workflow = FactoryBot.create(:existing_galaxy_ro_crate_workflow, other_creators: 'Jane Smith, John Smith')
    refute workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert_nil crate.author, 'Changes in SEEK should not be reflected in RO-Crate.'

    assert_not_equal crate.canonical_id, workflow.ro_crate.canonical_id
  end

  test 'can get and set source URL' do
    workflow = FactoryBot.create(:workflow)

    assert_no_difference('AssetLink.count') do
      workflow.source_link_url = 'https://github.com/seek4science/cool-workflow'
    end

    assert_difference('AssetLink.count', 1) do
      disable_authorization_checks { workflow.save! }
    end

    assert_equal 'https://github.com/seek4science/cool-workflow', workflow.source_link_url
    assert_equal 'https://github.com/seek4science/cool-workflow', workflow.source_link.url
  end

  test 'can clear source URL' do
    workflow = FactoryBot.create(:workflow, source_link_url: 'https://github.com/seek4science/cool-workflow')
    assert workflow.source_link
    assert workflow.source_link_url

    assert_no_difference('AssetLink.count') do
      workflow.source_link_url = nil
    end

    assert_difference('AssetLink.count', -1) do
      disable_authorization_checks { workflow.save! }
    end

    assert_nil workflow.reload.source_link
  end

  test 'generates RO-Crate and diagram for workflow/abstract workflow' do
    workflow = FactoryBot.create(:generated_galaxy_no_diagram_ro_crate_workflow)
    assert workflow.should_generate_crate?
    crate = nil

    crate = workflow.ro_crate

    assert crate.main_workflow
    assert crate.main_workflow_diagram
    assert crate.main_workflow_cwl
  end

  test 'generates RO-Crate and gracefully handles diagram error for workflow/abstract workflow' do
    bad_generator = MiniTest::Mock.new
    def bad_generator.write_graph(struct)
      raise 'oh dear'
    end

    Seek::WorkflowExtractors::CwlDotGenerator.stub :new, bad_generator do
      workflow = FactoryBot.create(:generated_galaxy_no_diagram_ro_crate_workflow)
      assert workflow.should_generate_crate?
      crate = nil

      crate = workflow.ro_crate

      assert crate.main_workflow
      refute crate.main_workflow_diagram
      assert crate.main_workflow_cwl
    end
  end

  test 'create a workflow using a workflow class that does not have an extractor' do
    workflow_class = WorkflowClass.create(title: 'New Type', key: 'newtype')
    workflow = FactoryBot.create(:workflow, workflow_class: workflow_class)

    assert workflow.valid?
  end

  test 'creates life monitor submission job on create if tests present' do
    workflow = nil
    with_config_value(:life_monitor_enabled, true) do
      assert_enqueued_with(job: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011',
                           policy: FactoryBot.create(:public_policy))
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end

      VCR.use_cassette('life_monitor/get_token') do
        VCR.use_cassette('life_monitor/non_existing_workflow_get') do
          VCR.use_cassette('life_monitor/submit_workflow') do
            assert_nothing_raised do
              User.current_user = workflow.contributor.user
              LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
            end
          end
        end
      end
    end
  end

  test 'creates life monitor submission job on create if tests present for git workflow' do
    workflow = nil
    with_config_value(:life_monitor_enabled, true) do
      assert_enqueued_with(job: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:ro_crate_git_workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011',
                           policy: FactoryBot.create(:public_policy))
        assert workflow.latest_git_version.has_tests?
        assert workflow.can_download?(nil)
      end

      VCR.use_cassette('life_monitor/get_token') do
        VCR.use_cassette('life_monitor/non_existing_workflow_get') do
          VCR.use_cassette('life_monitor/submit_workflow') do
            assert_nothing_raised do
              User.current_user = workflow.contributor.user
              LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
            end
          end
        end
      end
    end
  end

  test 'does not create life monitor submission job if life monitor disabled' do
    with_config_value(:life_monitor_enabled, false) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:public_policy))
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if no tests' do
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:generated_galaxy_no_diagram_ro_crate_workflow, policy: FactoryBot.create(:public_policy))
        refute workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if no tests in git workflow' do
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:ro_crate_git_workflow, policy: FactoryBot.create(:public_policy))
        refute workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if workflow not publicly accessible' do
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:private_policy))
        assert workflow.latest_version.has_tests?
        refute workflow.can_download?(nil)
      end
    end
  end

  test 'creates lifemonitor submission job on update if workflow made public' do
    workflow = nil
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = FactoryBot.create(:workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011', policy: FactoryBot.create(:private_policy))
        User.current_user = workflow.contributor.user
        assert workflow.latest_version.has_tests?
        refute workflow.can_download?(nil)
      end

      assert_enqueued_with(job: LifeMonitorSubmissionJob) do
        workflow.policy = FactoryBot.create(:public_policy)
        disable_authorization_checks { workflow.save! }
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end

      VCR.use_cassette('life_monitor/get_token') do
        VCR.use_cassette('life_monitor/non_existing_workflow_get') do
          VCR.use_cassette('life_monitor/submit_workflow') do
            assert_nothing_raised do
              LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
            end
          end
        end
      end
    end
  end

  test 'does not resubmit if workflow is already on life monitor' do
    workflow = FactoryBot.create(:workflow_with_tests, uuid: '86da0a30-d2cd-013a-a07d-000c29a94011', policy: FactoryBot.create(:public_policy))

    VCR.use_cassette('life_monitor/get_token') do
      VCR.use_cassette('life_monitor/existing_workflow_get') do
        # If it actually submitted here it would raise a VCR exception since we haven't loaded the `submit_workflow` tape
        assert_nothing_raised do
          LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
        end
      end
    end
  end

  test 'test_status is not carried over to new versions' do
    workflow = FactoryBot.create(:workflow_with_tests)
    disable_authorization_checks { workflow.update_test_status(:all_passing) }
    v1 = workflow.find_version(1)
    assert_equal :all_passing, v1.test_status
    assert_equal :all_passing, workflow.reload.test_status

    disable_authorization_checks do
      workflow.save_as_new_version('new version')
    end

    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.test_status
    assert_equal :all_passing, v1.test_status
  end

  test 'update test status' do
    # Default latest version
    workflow = FactoryBot.create(:workflow_with_tests, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing) }
    assert_equal :all_failing, workflow.reload.test_status
    assert_nil v1.test_status
    assert_equal :all_failing, v2.reload.test_status

    # Explicit latest version
    workflow = FactoryBot.create(:workflow_with_tests, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing, 2) }
    assert_equal :all_failing, workflow.reload.test_status
    assert_nil v1.reload.test_status
    assert_equal :all_failing, v2.reload.test_status

    # Explicit non-latest version
    workflow = FactoryBot.create(:workflow_with_tests, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing, 1) }
    assert_nil workflow.reload.test_status
    assert_equal :all_failing, v1.reload.test_status
    assert_nil v2.reload.test_status
  end

  test 'test_status is not carried over to new git versions' do
    workflow = FactoryBot.create(:ro_crate_git_workflow)
    disable_authorization_checks { workflow.update_test_status(:all_passing) }
    v1 = workflow.find_version(1)
    assert_equal :all_passing, v1.test_status
    assert_equal :all_passing, workflow.reload.test_status

    disable_authorization_checks do
      s = workflow.save_as_new_git_version(ref: 'refs/heads/master')
      assert s
    end

    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.test_status
    assert_equal :all_passing, v1.test_status
  end

  test 'test_status is preserved when freezing git versions' do
    workflow = FactoryBot.create(:local_ro_crate_git_workflow_with_tests)

    disable_authorization_checks { workflow.update_test_status(:all_passing) }
    v1 = workflow.find_version(1)
    v1.update_column(:mutable, true)
    v1.reload
    assert_equal :all_passing, v1.test_status
    assert_equal :all_passing, workflow.reload.test_status
    assert v1.mutable?

    disable_authorization_checks do
      v1.lock
    end

    refute v1.mutable?
    assert_equal :all_passing, v1.test_status
    assert_equal :all_passing, workflow.reload.test_status
  end

  test 'update test status for git versioned workflows' do
    # Default latest version
    workflow = FactoryBot.create(:local_ro_crate_git_workflow, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_git_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing) }
    assert_equal :all_failing, workflow.reload.test_status
    assert_nil v1.test_status
    assert_equal :all_failing, v2.reload.test_status

    # Explicit latest version
    workflow = FactoryBot.create(:local_ro_crate_git_workflow, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_git_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing, 2) }
    assert_equal :all_failing, workflow.reload.test_status
    assert_nil v1.reload.test_status
    assert_equal :all_failing, v2.reload.test_status

    # Explicit non-latest version
    workflow = FactoryBot.create(:local_ro_crate_git_workflow, test_status: nil)
    v1 = workflow.find_version(1)
    disable_authorization_checks { workflow.save_as_new_git_version }
    v2 = workflow.find_version(2)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    disable_authorization_checks { workflow.update_test_status(:all_failing, 1) }
    assert_nil workflow.reload.test_status
    assert_equal :all_failing, v1.reload.test_status
    assert_nil v2.reload.test_status
  end

  test 'updating test status does not trigger life monitor submission job' do
    workflow = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:public_policy), test_status: nil)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        disable_authorization_checks { workflow.update_test_status(:all_failing) }
      end
    end
  end

  test 'updating other workflow fields does trigger life monitor submission job' do
    workflow = FactoryBot.create(:workflow_with_tests, policy: FactoryBot.create(:public_policy), test_status: nil)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    with_config_value(:life_monitor_enabled, true) do
      assert_enqueued_jobs(1, only: LifeMonitorSubmissionJob) do
        disable_authorization_checks { workflow.update!(title: 'something') }
      end
    end
  end

  test 'updating test status does not trigger life monitor submission job for git workflow' do
    workflow = FactoryBot.create(:local_ro_crate_git_workflow_with_tests, policy: FactoryBot.create(:public_policy), test_status: nil)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        disable_authorization_checks { workflow.update_test_status(:all_failing) }
      end
    end
  end

  test 'updating other workflow fields does trigger life monitor submission job for git workflow' do
    workflow = FactoryBot.create(:local_ro_crate_git_workflow_with_tests, policy: FactoryBot.create(:public_policy), test_status: nil)
    assert_nil workflow.reload.test_status
    assert_nil workflow.latest_version.reload.test_status
    with_config_value(:life_monitor_enabled, true) do
      assert_enqueued_jobs(1, only: LifeMonitorSubmissionJob) do
        disable_authorization_checks { workflow.update!(title: 'something') }
      end
    end
  end

  test 'changing main workflow path refreshes internals structure' do
    workflow = FactoryBot.create(:local_git_workflow)
    v = workflow.git_version

    disable_authorization_checks do
      v.refresh_internals
      v.save!
      v.add_file('1-PreProcessing.ga', open_fixture_file('workflows/1-PreProcessing.ga'))
    end

    assert_equal 'concat_two_files.ga', v.main_workflow_path
    assert_equal 2, v.inputs.count
    assert_equal 1, v.steps.count
    assert_equal 1, v.outputs.count

    disable_authorization_checks do
      v.main_workflow_path = '1-PreProcessing.ga'
      assert v.main_workflow_path_changed?
      v.save!
    end

    assert_equal '1-PreProcessing.ga', v.main_workflow_path
    assert_equal 2, v.inputs.length
    assert_equal 15, v.steps.length
    assert_equal 31, v.outputs.length
  end

  test 'changing diagram path clears the cached diagram' do
    workflow = FactoryBot.create(:local_git_workflow)
    v = workflow.git_version
    original_diagram = v.diagram
    assert original_diagram

    disable_authorization_checks do
      v.add_file('new-diagram.png', open_fixture_file('file_picture.png'))
    end

    assert_equal 'diagram.png', v.diagram_path
    assert original_diagram.exists?
    assert_equal 32248, original_diagram.size

    disable_authorization_checks do
      v.diagram_path = 'new-diagram.png'
      assert v.diagram_path_changed?
      v.save!
    end

    assert_equal 'new-diagram.png', v.diagram_path
    refute v.diagram_exists?
    new_diagram = v.diagram

    assert new_diagram.exists?
    assert_equal 2728, new_diagram.size
  end

  test 'adding diagram path clears the cached auto-generated diagram' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow,
                       workflow_class: WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class))

    v = workflow.git_version
    disable_authorization_checks do
      v.main_workflow_path = 'Concat_two_files.cwl'
      v.save!
    end

    assert v.can_render_diagram?
    original_diagram = v.diagram # Generates a diagram from the CWL
    assert original_diagram

    disable_authorization_checks do
      v.add_file('new-diagram.png', open_fixture_file('file_picture.png'))
    end

    assert_nil v.diagram_path, 'Diagram path should not be set, it is generated.'
    assert original_diagram.exists?
    original_size = original_diagram.size
    assert original_size > 100
    assert original_size < 50000
    original_sha1sum = original_diagram.sha1sum

    disable_authorization_checks do
      v.diagram_path = 'new-diagram.png'
      assert v.diagram_path_changed?
      v.save!
    end

    assert_equal 'new-diagram.png', v.diagram_path
    refute v.diagram_exists?
    new_diagram = v.diagram

    assert new_diagram.exists?
    assert_equal 2728, new_diagram.size
    assert_not_equal original_sha1sum, new_diagram.sha1sum
  end


  test 'removing diagram path reverts to the auto-generated diagram' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow,
                       workflow_class: WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class))

    v = workflow.git_version
    disable_authorization_checks do
      v.main_workflow_path = 'Concat_two_files.cwl'
      v.diagram_path = 'diagram.png'
      v.save!
    end

    v = workflow.git_version
    original_diagram = v.diagram
    assert original_diagram

    disable_authorization_checks do
      v.add_file('new-diagram.png', open_fixture_file('file_picture.png'))
    end

    assert_equal 'diagram.png', v.diagram_path
    assert original_diagram.exists?
    assert_equal 32248, original_diagram.size
    original_sha1sum = original_diagram.sha1sum

    disable_authorization_checks do
      v.diagram_path = nil
      assert v.diagram_path_changed?
      v.save!
    end

    assert_nil v.diagram_path
    refute v.diagram_exists?
    assert v.can_render_diagram?
    new_diagram = v.diagram # Generates diagram

    assert new_diagram.exists?
    assert new_diagram.size > 100
    assert new_diagram.size < 50000
    assert_not_equal original_sha1sum, new_diagram.sha1sum
  end

  test 'generates RO-Crate for workflow with auto-generated diagram' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow,
                       workflow_class: WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class))

    v = workflow.git_version
    disable_authorization_checks do
      v.main_workflow_path = 'Concat_two_files.cwl'
      v.save!
    end

    v = workflow.git_version
    original_diagram = v.diagram
    assert original_diagram
    assert_nil v.diagram_path, 'Diagram path should not be set, it is generated.'

    assert_nothing_raised do
      crate = workflow.ro_crate
      assert crate.main_workflow
      assert crate.main_workflow_diagram
      assert_equal original_diagram.size, crate.main_workflow_diagram.content_size
    end
  end

  test 'search terms for git workflows' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow, workflow_class: FactoryBot.create(:unextractable_workflow_class))

    v = nil
    disable_authorization_checks do
      v = workflow.git_version
      c = v.add_files(
        [['main.ga', StringIO.new('{ "a_galaxy_workflow" : true, "Yes" : "yep", "OK" : "yep", "Cool" : "yep" } ')],
         ['README.md', StringIO.new('unique_string_banana a b c d e')],
         ['LICENSE', StringIO.new('unique_string_grapefruit f g h i j k')]])
      v.main_workflow_path = 'main.ga'
      v.commit = c
      v.save!
    end

    terms = v.search_terms

    assert(terms.any? { |t| t.include?('a_galaxy_workflow') })
    assert(terms.any? { |t| t.include?('unique_string_banana') })
    refute(terms.any? { |t| t.include?('unique_string_grapefruit') })
  end

  test 'updating workflow synchronizes metadata on git version' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow, workflow_class: FactoryBot.create(:unextractable_workflow_class))
    assert workflow.git_version.mutable
    disable_authorization_checks do
      workflow.update!(title: 'new title')
      assert_equal 'new title', workflow.reload.title
      assert_equal 'new title', workflow.git_version.reload.title
    end
  end

  test 'updating workflow synchronizes metadata on immutable git version' do
    workflow = FactoryBot.create(:annotationless_local_git_workflow, workflow_class: FactoryBot.create(:unextractable_workflow_class))
    disable_authorization_checks do
      workflow.git_version.lock
      refute workflow.git_version.mutable
      workflow.update!(title: 'new title')
      assert_equal 'new title', workflow.reload.title
      assert_equal 'new title', workflow.git_version.reload.title
    end
  end

  test 'tags and ontology annotations in json api' do
    FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab
    FactoryBot.create(:operations_controlled_vocab) unless SampleControlledVocab::SystemVocabs.operations_controlled_vocab

    user = FactoryBot.create(:user)

    workflow = User.with_current_user(user) do
      FactoryBot.create(:max_workflow, contributor: user.person)
    end

    json = WorkflowSerializer.new(workflow).as_json

    assert_equal ["Workflow-tag1", "Workflow-tag2", "Workflow-tag3", "Workflow-tag4", "Workflow-tag5"], json[:tags]

    assert_equal [{label:'Clustering', identifier: 'http://edamontology.org/operation_3432'}], json[:operation_annotations]
    assert_equal [{label:'Chemistry', identifier: 'http://edamontology.org/topic_3314'}], json[:topic_annotations]
  end

  test 'ontology annotation properties'do
    wf = FactoryBot.create(:workflow)

    assert wf.supports_controlled_vocab_annotations?
    assert wf.supports_controlled_vocab_annotations?(:topics)
    assert wf.supports_controlled_vocab_annotations?(:operations)
    refute wf.supports_controlled_vocab_annotations?(:data_formats)
    refute wf.supports_controlled_vocab_annotations?(:data_types)

    assert wf.respond_to?(:topic_annotations)
    assert wf.respond_to?(:operation_annotations)
    refute wf.respond_to?(:data_format_annotations)
    refute wf.respond_to?(:data_type_annotations)
  end

  test 'associate tools with workflow' do
    wf = FactoryBot.create(:workflow)

    assert_difference('BioToolsLink.count', 3) do
      wf.tools_attributes = [
        { bio_tools_id: 'thing-doer', name: 'ThingDoer'},
        { bio_tools_id: 'database-accessor', name: 'DatabaseAccessor'},
        { bio_tools_id: 'ruby', name: 'Ruby'}
      ]

      disable_authorization_checks { wf.save! }
      assert_equal %w[database-accessor ruby thing-doer],
                   wf.bio_tools_links.pluck(:bio_tools_id).sort
    end
  end

  test 'associating tools with workflow does not create duplicate annotation records' do
    wf = FactoryBot.create(:workflow)
    disable_authorization_checks do
      wf.tools_attributes = [
        { bio_tools_id: 'thing-doer', name: 'ThingDoer'},
        { bio_tools_id: 'database-accessor', name: 'DatabaseAccessor'},
        { bio_tools_id: 'python', name: 'Python'},
        { bio_tools_id: 'ruby', name: 'Ruby'}
      ]
      wf.save!
    end
    thing_doer = wf.bio_tools_links.where(bio_tools_id: 'thing-doer').first
    orig_id = thing_doer.id

    assert_difference('BioToolsLink.count', -1, 'should have removed redundant annotation') do
      wf.tools_attributes = [
        { bio_tools_id: 'thing-doer', name: 'ThingDoer!!!'},
        { bio_tools_id: 'database-accessor', name: 'DatabaseAccessor'},
        { bio_tools_id: 'javascript', name: 'JavaScript'}
      ]

      disable_authorization_checks { wf.save! }
      assert_includes wf.bio_tools_link_ids, orig_id
      assert_equal 'ThingDoer!!!', thing_doer.reload.name, 'Should update name of tool'
      assert_equal %w[database-accessor javascript thing-doer],
                   wf.bio_tools_links.pluck(:bio_tools_id).sort
    end
  end

  test 'cannot delete workflow with doi' do
    workflow = FactoryBot.create(:workflow)
    v = workflow.latest_version
    User.with_current_user(workflow.contributor.user) do
      assert workflow.state_allows_delete?
      assert workflow.can_delete?

      assert v.update(doi: '10.81082/dev-workflowhub.workflow.136.1')

      refute workflow.state_allows_delete?
      refute workflow.can_delete?
    end
  end

  test 'cannot delete git workflow with doi' do
    workflow = FactoryBot.create(:local_git_workflow)
    v = workflow.git_version
    User.with_current_user(workflow.contributor.user) do
      assert workflow.state_allows_delete?
      assert workflow.can_delete?

      assert v.update(doi: '10.81082/dev-workflowhub.workflow.136.1')

      refute workflow.state_allows_delete?
      refute workflow.can_delete?
    end
  end

  test 'sets deleted_contributor after contributor deleted' do
    workflow = FactoryBot.create(:local_git_workflow)
    assert_nil workflow.deleted_contributor
    refute workflow.has_deleted_contributor?

    disable_authorization_checks do
      workflow.contributor.destroy!
    end

    workflow.reload
    assert workflow.deleted_contributor
    assert workflow.has_deleted_contributor?
  end

  test 'sets maturity level' do
    workflow = FactoryBot.create(:local_git_workflow)
    disable_authorization_checks do
      workflow.maturity_level = :released
      assert workflow.save
      assert_equal :released, workflow.maturity_level

      workflow.maturity_level = :work_in_progress
      assert workflow.save
      assert_equal :work_in_progress, workflow.maturity_level

      workflow.maturity_level = :deprecated
      assert workflow.save
      assert_equal :deprecated, workflow.maturity_level

      workflow.maturity_level = :something
      assert workflow.save
      assert_nil workflow.maturity_level
    end
  end
end
