require 'test_helper'

class VersioningCompatibilityTest < ActiveSupport::TestCase
  setup do
    @standard_workflow = FactoryBot.create(:workflow)
    disable_authorization_checks do
      @standard_workflow.save_as_new_version('new version')
      FactoryBot.create(:cwl_content_blob, asset: @standard_workflow, asset_version: 2)
    end

    @git_workflow = FactoryBot.create(:local_git_workflow)
    disable_authorization_checks do
      @git_workflow.latest_git_version.next_version.save!
    end

    @converted_workflow = FactoryBot.create(:workflow)
    disable_authorization_checks do
      @converted_workflow.save_as_new_version('new version')
      FactoryBot.create(:cwl_content_blob, asset: @converted_workflow, asset_version: 2)
      Git::Converter.new(@converted_workflow.reload).convert(unzip: true)
      @converted_workflow.latest_git_version.next_version.save! # v3
    end
  end

  test 'is_git_versioned?' do
    refute @standard_workflow.is_git_versioned?

    assert @git_workflow.is_git_versioned?

    assert @converted_workflow.is_git_versioned?
  end

  test 'latest_version' do
    latest_standard_workflow = @standard_workflow.latest_version
    assert_equal 'Workflow::Version', latest_standard_workflow.class.name
    assert_equal 2, latest_standard_workflow.version
    assert_equal latest_standard_workflow, @standard_workflow.latest_standard_version

    latest_git_workflow = @git_workflow.latest_version
    assert_equal 'Workflow::Git::Version', latest_git_workflow.class.name
    assert_equal 2, latest_git_workflow.version
    assert_equal latest_git_workflow, @git_workflow.latest_git_version

    latest_converted_workflow = @converted_workflow.latest_version
    assert_equal 'Workflow::Git::Version', latest_converted_workflow.class.name
    assert_equal 3, latest_converted_workflow.version
    assert_equal latest_converted_workflow, @converted_workflow.latest_git_version
    latest_converted_workflow_std = @converted_workflow.latest_standard_version
    assert_equal 'Workflow::Version', latest_converted_workflow_std.class.name
    assert_equal 2, latest_converted_workflow_std.version
  end

  test 'previous_version' do
    previous_standard_workflow = @standard_workflow.previous_version
    assert_equal 'Workflow::Version', previous_standard_workflow.class.name
    assert_equal 1, previous_standard_workflow.version
    assert_equal previous_standard_workflow, @standard_workflow.previous_standard_version

    previous_git_workflow = @git_workflow.previous_version
    assert_equal 'Workflow::Git::Version', previous_git_workflow.class.name
    assert_equal 1, previous_git_workflow.version
    assert_equal previous_git_workflow, @git_workflow.previous_git_version

    previous_converted_workflow = @converted_workflow.previous_version
    assert_equal 'Workflow::Git::Version', previous_converted_workflow.class.name
    assert_equal 2, previous_converted_workflow.version
    assert_equal previous_converted_workflow, @converted_workflow.previous_git_version
    previous_converted_workflow_std = @converted_workflow.previous_standard_version
    assert_equal 'Workflow::Version', previous_converted_workflow_std.class.name
    assert_equal 1, previous_converted_workflow_std.version
  end

  test 'version' do
    assert_equal 2, @standard_workflow.version
    assert_equal 2, @standard_workflow.latest_version.version

    assert_equal 2, @git_workflow.version
    assert_equal 2, @git_workflow.latest_version.version

    assert_equal 3, @converted_workflow.version
    assert_equal 3, @converted_workflow.latest_version.version
    assert_equal 2, @converted_workflow.latest_standard_version.version
  end

  test 'versions' do
    assert @standard_workflow.versions.all? { |v| v.is_a?(Workflow::Version) }

    assert @git_workflow.versions.all? { |v| v.is_a?(Workflow::Git::Version) }

    assert @converted_workflow.versions.all? { |v| v.is_a?(Workflow::Git::Version) }
  end

  test 'visible_versions' do
    assert @standard_workflow.visible_versions.all? { |v| v.is_a?(Workflow::Version) }

    assert @git_workflow.visible_versions.all? { |v| v.is_a?(Workflow::Git::Version) }

    assert @converted_workflow.visible_versions.all? { |v| v.is_a?(Workflow::Git::Version) }

    assert_equal 2, @converted_workflow.visible_standard_versions.length
    assert_equal 3, @converted_workflow.visible_git_versions.length

    disable_authorization_checks do
      @converted_workflow.find_standard_version(1).update!(visibility: :private)
    end

    assert_equal 1, @converted_workflow.visible_standard_versions.length
    assert_equal 3, @converted_workflow.visible_git_versions.length
  end

  test 'find_version' do
    assert_equal 'Workflow::Version', @standard_workflow.find_version(1).class.name
    assert_equal 'Workflow::Version', @standard_workflow.find_version(2).class.name
    assert_nil @standard_workflow.find_version(3)

    assert_equal 'Workflow::Git::Version', @git_workflow.find_version(1).class.name
    assert_equal 'Workflow::Git::Version', @git_workflow.find_version(2).class.name
    assert_nil @git_workflow.find_version(3)

    assert_equal 'Workflow::Git::Version', @converted_workflow.find_version(1).class.name
    assert_equal 'Workflow::Git::Version', @converted_workflow.find_version(3).class.name
    assert_nil @converted_workflow.find_version(4)
  end

  test 'update_version only affects standard versions' do
    disable_authorization_checks do
      @converted_workflow.update_version(1, { title: 'hello world' })
    end

    assert_equal 'hello world', @converted_workflow.find_standard_version(1).title
    assert_not_equal 'hello world', @converted_workflow.find_git_version(1).title
  end

  test 'destroy_version only affects standard versions' do
    with_config_value(:delete_asset_version_enabled, true) do
      disable_authorization_checks do
        assert @converted_workflow.destroy_version(1)
      end
    end

    assert_nil @converted_workflow.find_standard_version(1)
    refute_nil @converted_workflow.find_git_version(1)
  end
end