require 'test_helper'

class GitWorkflowRoCrateApiTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    user_login
    FactoryBot.create(:cwl_workflow_class) # Make sure the CWL class is present
    FactoryBot.create(:nextflow_workflow_class)
    FactoryBot.create(:galaxy_workflow_class)
    @project = current_person.projects.first
    @git_support = Seek::Config.git_support_enabled
    Seek::Config.git_support_enabled = true
  end

  teardown do
    Seek::Config.git_support_enabled = @git_support
  end

  test 'can post RO-Crate' do
    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/ro-crate-nf-core-ampliseq.crate.zip'),
        workflow: {
          project_ids: [@project.id]
        }
      }, headers: { 'Authorization' => write_access_auth }

      assert_response :success
      assert_equal 'Nextflow', assigns(:workflow).workflow_class.title
      assert_equal 'nf-core/ampliseq', assigns(:workflow).title
      assert assigns(:workflow).git_version.total_size > 100
      assert_equal 'main.nf', assigns(:workflow).ro_crate.main_workflow.id
    end
  end

  test 'can post RO-Crate as new version' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy), contributor: current_person)

    assert_no_difference('Workflow.count') do
      assert_difference('Git::Version.count', 1) do
        post create_version_workflow_path(workflow.id), params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-nf-core-ampliseq.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          },
          revision_comments: 'new ver'
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        workflow = assigns(:workflow).reload
        old_version = workflow.find_version(1)
        new_version = workflow.git_version

        assert_equal 2, workflow.version
        assert_equal 'Nextflow', workflow.workflow_class.title
        assert_equal 'Nextflow', new_version.workflow_class.title
        assert_equal 'Galaxy', old_version.workflow_class.title
        assert_equal 'nf-core/ampliseq', workflow.title
        assert_equal 'nf-core/ampliseq', new_version.title
        assert_equal 'Concat two files', old_version.title
        assert new_version.total_size > 100
        assert_equal 'main.nf', workflow.main_workflow_path
        assert_equal 'main.nf', new_version.main_workflow_path
        assert_equal 'main.nf', workflow.ro_crate.main_workflow.id
        assert_equal 'concat_two_files.ga', old_version.main_workflow_path

        assert new_version.file_exists?('main.nf')
        refute new_version.file_exists?('concat_two_files.ga')

        refute old_version.file_exists?('main.nf')
        assert old_version.file_exists?('concat_two_files.ga')
      end
    end
  end

  test 'cannot post RO-Crate as new version to remote git workflows' do
    workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy), contributor: current_person)

    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post create_version_workflow_path(workflow.id), params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-nf-core-ampliseq.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          },
          revision_comments: 'new ver'
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :unprocessable_entity
        assert JSON.parse(@response.body)['errors'].any? { |e| e['detail'].include?('Cannot add RO-Crate to remote workflows') }
      end
    end
  end

  test 'cannot post RO-Crate with missing metadata' do
    assert_no_difference('Workflow.count') do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/workflow-4-1.crate.zip'),
        workflow: {
          project_ids: [@project.id]
        }
      }, headers: { 'Authorization' => write_access_auth }

      assert_response :unprocessable_entity
      assert JSON.parse(@response.body)['errors'].any? { |e| e['detail'].include?("can't be blank") }
    end
  end

  test 'can supplement metadata when posting RO-Crate' do
    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/workflow-4-1.crate.zip'),
        workflow: {
          title: 'Alternative title',
          project_ids: [@project.id]
        }
      }, headers: { 'Authorization' => write_access_auth }

      assert_response :success
      assert_equal 'Alternative title', assigns(:workflow).title
    end
  end

  test 'can identify license from URI' do
    assert_difference('Workflow.count', 1) do
      post workflows_path, params: {
        ro_crate: fixture_file_upload('workflows/ro-crate-with-uri-license.crate.zip'),
        workflow: {
          project_ids: [@project.id]
        }
      }, headers: { 'Authorization' => write_access_auth }

      assert_response :success
      assert_equal 'MIT', assigns(:workflow).license
    end
  end

  test 'can submit RO-Crate with ID' do
    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        assert_equal '1.0.0', assigns(:workflow).git_version.name
        assert_equal 'sort-and-change-case', assigns(:workflow).title
        assert_equal 'https://example.com/my-workflow', assigns(:workflow).source_link_url
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'sort-and-change-case.ga', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'can submit RO-Crate with numeric ID' do
    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-numeric-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        assert_equal '3.2', assigns(:workflow).git_version.name
        assert_equal 'sort-and-change-case', assigns(:workflow).title
        assert_equal 'https://example.com/my-workflow', assigns(:workflow).source_link_url
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'sort-and-change-case.ga', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'cannot submit RO-Crate without ID' do
    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-uri-license.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :unprocessable_entity
        assert JSON.parse(@response.body)['errors'].any? { |e| e['detail'].include?('source URL could not be determined') }
      end
    end
  end

  test 'cannot submit RO-Crate without version' do
    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id-but-no-version.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :unprocessable_entity
        assert JSON.parse(@response.body)['errors'].any? { |e| e['detail'].include?('version could not be determined') }
      end
    end
  end

  test 'can submit RO-Crate that adds a version to an existing workflow' do
    workflow = FactoryBot.create(:local_git_workflow, source_link_url: 'https://example.com/my-workflow', contributor: current_person)

    assert_no_difference('Workflow.count') do
      assert_difference('Git::Version.count', 1) do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        assert_equal 'sort-and-change-case', assigns(:workflow).title
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'sort-and-change-case.ga', assigns(:workflow).ro_crate.main_workflow.id
        assert_equal '1.0.0', assigns(:workflow).git_version.name

        workflow.reload
        assert_equal 2, workflow.version
        old_version = workflow.find_version(1)
        new_version = workflow.git_version
        refute new_version.file_exists?('concat_two_files.ga')
        assert new_version.file_exists?('sort-and-change-case.ga')
        assert old_version.file_exists?('concat_two_files.ga')
        refute old_version.file_exists?('sort-and-change-case.ga')
      end
    end
  end

  test 'duplicate version ignored when submitting RO-Crate' do
    workflow = FactoryBot.create(:local_git_workflow, source_link_url: 'https://example.com/my-workflow', contributor: current_person)
    disable_authorization_checks { workflow.git_version.update!(name: '1.0.0') }

    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        assert_equal 'Concat two files', assigns(:workflow).title
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'concat_two_files.ga', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'duplicate numeric version ignored when submitting RO-Crate' do
    workflow = FactoryBot.create(:local_git_workflow, source_link_url: 'https://example.com/my-workflow', contributor: current_person)
    disable_authorization_checks { workflow.git_version.update!(name: '3.2') }

    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-numeric-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        assert_equal 'Concat two files', assigns(:workflow).title
        assert assigns(:workflow).git_version.total_size > 100
        assert_equal 'concat_two_files.ga', assigns(:workflow).ro_crate.main_workflow.id
      end
    end
  end

  test 'cannot submit RO-Crate with ambiguous matching ID' do
    workflow = FactoryBot.create(:local_git_workflow, source_link_url: 'https://example.com/my-workflow', contributor: current_person)
    workflow2 = FactoryBot.create(:local_git_workflow, source_link_url: 'https://example.com/my-workflow', contributor: current_person)

    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :unprocessable_entity
        assert JSON.parse(@response.body)['errors'].any? { |e| e['detail'].include?('2 workflows found matching the given ID.') }
      end
    end
  end

  test 'cannot submit RO-Crate with read-only token' do
    assert_no_difference('Workflow.count') do
      assert_no_difference('Git::Version.count') do
        post submit_workflows_path, as: :json, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => read_access_auth }

        assert_response :forbidden
      end
    end
  end

  test 'submitted workflow takes project default policy' do
    project_admin = FactoryBot.create(:project_administrator)
    disable_authorization_checks do
      @project.default_policy = FactoryBot.create(:private_policy)
      @project.default_policy.permissions << Permission.new(contributor: @project, access_type: Policy::EDITING)
      @project.default_policy.permissions << Permission.new(contributor: project_admin, access_type: Policy::MANAGING)
      @project.default_policy.save!
      @project.use_default_policy = true
      @project.save!
    end

    assert_difference('Workflow.count', 1) do
      assert_difference('Git::Version.count', 1) do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [@project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :success
        assert_equal 'Galaxy', assigns(:workflow).workflow_class.title
        policy = assigns(:workflow).policy
        assert_equal 2, policy.permissions.count
        assert policy.permissions.detect { |p| p.contributor == project_admin && p.access_type == Policy::MANAGING }
        assert policy.permissions.detect { |p| p.contributor == @project && p.access_type == Policy::EDITING }
      end
    end
  end

  test 'cannot submit RO-Crate to project without membership' do
    project = FactoryBot.create(:project)
    assert_no_difference('Workflow.count', 1) do
      assert_no_difference('Git::Version.count', 1) do
        post submit_workflows_path, params: {
          ro_crate: fixture_file_upload('workflows/ro-crate-with-id.crate.zip'),
          workflow: {
            project_ids: [project.id]
          }
        }, headers: { 'Authorization' => write_access_auth }

        assert_response :unprocessable_entity
        h = JSON.parse(response.body)
        errors = h["errors"]
        assert errors.first['detail'].include?('member of')
      end
    end
  end
end