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

    assert_equal 'MIT', crate.license

    authors = crate.author.map(&:name)
    assert_includes authors, 'John Smith'
    assert_includes authors, 'Jane Smith'
    assert crate.author.detect { |a| a['identifier'] == URI.join(Seek::Config.site_base_host, "people/#{creator.id}").to_s }

    assert_equal URI.join(Seek::Config.site_base_host, "projects/#{workflow.projects.first.id}").to_s, crate['provider'].first.dereference['identifier']
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
end
