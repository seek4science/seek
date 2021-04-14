require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  test 'validations' do
    workflow = Factory :workflow
    workflow.title = ''

    assert !workflow.valid?

    workflow.reload
  end

  test "new workflow's version is 1" do
    workflow = Factory :workflow
    assert_equal 1, workflow.version
  end

  test 'can create new version of workflow' do
    workflow = Factory :workflow
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
    workflow = Factory :workflow
    assert workflow.sops.empty?

    User.with_current_user(workflow.contributor.user) do
      assert_difference 'workflow.sops.count' do
        workflow.sops << Factory(:sop, contributor:workflow.contributor)
      end
    end
  end

  test 'has uuid' do
    workflow = Factory :workflow
    assert_not_nil workflow.uuid
  end

  test 'generates fresh RO crate for individual workflow' do
    workflow = Factory(:cwl_workflow, license: 'MIT', other_creators: 'Jane Smith, John Smith')
    creator = Factory(:person)
    workflow.creators << creator
    assert workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert crate.main_workflow
    refute crate.main_workflow_diagram
    refute crate.main_workflow_cwl
    assert_equal 'Common Workflow Language', crate.main_workflow.programming_language['name']

    assert_equal Seek::License.find('MIT')&.url, crate.main_workflow['license']

    # authors = crate.main_workflow['creator'].map(&:name)
    # assert_includes authors, 'John Smith'
    # assert_includes authors, 'Jane Smith'
    # assert crate.author.detect { |a| a['identifier'] == URI.join(Seek::Config.site_base_host, "people/#{creator.id}").to_s }

    assert_equal URI.join(Seek::Config.site_base_host, "projects/#{workflow.projects.first.id}").to_s, crate.main_workflow['producer']['@id']
  end

  test 'generates fresh RO crate for workflow/diagram/abstract workflow' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, other_creators: 'Jane Smith, John Smith')
    assert workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert crate.main_workflow
    assert crate.main_workflow_diagram
    assert crate.main_workflow_cwl

    assert_equal 'Galaxy', crate.main_workflow.programming_language['name']
    assert_equal 'Common Workflow Language', crate.main_workflow_cwl.programming_language['name']
  end

  test 'serves existing RO crate for RO crate workflow' do
    workflow = Factory(:existing_galaxy_ro_crate_workflow, other_creators: 'Jane Smith, John Smith')
    refute workflow.should_generate_crate?

    crate = workflow.ro_crate

    assert_nil crate.author, 'Changes in SEEK should not be reflected in RO crate.'

    assert_not_equal crate.canonical_id, workflow.ro_crate.canonical_id
  end

  test 'can get and set source URL' do
    workflow = Factory(:workflow)

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
    workflow = Factory(:workflow, source_link_url: 'https://github.com/seek4science/cool-workflow')
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

  test 'generates RO crate and diagram for workflow/abstract workflow' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      workflow = Factory(:generated_galaxy_no_diagram_ro_crate_workflow)
      assert workflow.should_generate_crate?
      crate = nil

      VCR.use_cassette('workflows/cwl_viewer_galaxy_workflow_abstract_cwl_diagram') do
        crate = workflow.ro_crate
      end

      assert crate.main_workflow
      assert crate.main_workflow_diagram
      assert crate.main_workflow_cwl
    end
  end

  test 'generates RO crate and gracefully handles diagram error for workflow/abstract workflow' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      workflow = Factory(:generated_galaxy_no_diagram_ro_crate_workflow)
      assert workflow.should_generate_crate?
      crate = nil

      VCR.use_cassette('workflows/cwl_viewer_error') do
        crate = workflow.ro_crate
      end

      assert crate.main_workflow
      refute crate.main_workflow_diagram
      assert crate.main_workflow_cwl
    end
  end

  test 'create a workflow using a workflow class that does not have an extractor' do
    workflow_class = WorkflowClass.create(title: 'New Type', key: 'newtype')
    workflow = Factory(:workflow, workflow_class: workflow_class)

    assert workflow.valid?
  end

  test 'creates life monitor submission job on create if tests present' do
    workflow = nil
    with_config_value(:life_monitor_enabled, true) do
      assert_enqueued_with(job: LifeMonitorSubmissionJob) do
        workflow = Factory(:workflow_with_tests, uuid: '56c50ac0-529b-0139-9132-000c29a94011',
                           policy: Factory(:public_policy))
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end

      VCR.use_cassette('life_monitor/get_token') do
        VCR.use_cassette('life_monitor/non_existing_workflow_get') do
          VCR.use_cassette('life_monitor/submit_workflow') do
            assert_nothing_raised do
              User.current_user = workflow.contributor.user
              refute workflow.latest_version.monitored
              LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
              assert workflow.latest_version.reload.monitored
            end
          end
        end
      end
    end
  end

  test 'does not create life monitor submission job if life monitor disabled' do
    with_config_value(:life_monitor_enabled, false) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = Factory(:workflow_with_tests, policy: Factory(:public_policy))
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if no tests' do
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = Factory(:generated_galaxy_no_diagram_ro_crate_workflow, policy: Factory(:public_policy))
        refute workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if workflow not publicly accessible' do
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = Factory(:workflow_with_tests, policy: Factory(:private_policy))
        assert workflow.latest_version.has_tests?
        refute workflow.can_download?(nil)
      end
    end
  end

  test 'does not create life monitor submission job if workflow already monitored' do
    workflow = Factory(:workflow_with_tests, policy: Factory(:private_policy))
    workflow.latest_version.update_column(:monitored, true)
    workflow.policy.update_column(:access_type, Policy::ACCESSIBLE)
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        assert workflow.latest_version.has_tests?
        assert workflow.latest_version.monitored
        assert workflow.can_download?(nil)
        disable_authorization_checks { workflow.save! }
      end
    end
  end

  test 'creates lifemonitor submission job on update if workflow made public' do
    workflow = nil
    with_config_value(:life_monitor_enabled, true) do
      assert_no_enqueued_jobs(only: LifeMonitorSubmissionJob) do
        workflow = Factory(:workflow_with_tests, uuid: '56c50ac0-529b-0139-9132-000c29a94011', policy: Factory(:private_policy))
        User.current_user = workflow.contributor.user
        assert workflow.latest_version.has_tests?
        refute workflow.can_download?(nil)
        refute workflow.latest_version.monitored
      end

      assert_enqueued_with(job: LifeMonitorSubmissionJob) do
        workflow.policy = Factory(:public_policy)
        disable_authorization_checks { workflow.save! }
        assert workflow.latest_version.has_tests?
        assert workflow.can_download?(nil)
        refute workflow.latest_version.monitored
      end

      VCR.use_cassette('life_monitor/get_token') do
        VCR.use_cassette('life_monitor/non_existing_workflow_get') do
          VCR.use_cassette('life_monitor/submit_workflow') do
            assert_nothing_raised do
              refute workflow.latest_version.monitored
              LifeMonitorSubmissionJob.perform_now(workflow.latest_version)
              assert workflow.latest_version.reload.monitored
            end
          end
        end
      end
    end
  end

  test 'does not resubmit if workflow is already on life monitor' do
    workflow = Factory(:workflow_with_tests, uuid: '56c50ac0-529b-0139-9132-000c29a94011', policy: Factory(:public_policy))

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
    workflow = Factory(:workflow_with_tests)
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
    workflow = Factory(:workflow_with_tests, test_status: nil)
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
    workflow = Factory(:workflow_with_tests, test_status: nil)
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
    workflow = Factory(:workflow_with_tests, test_status: nil)
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
end
