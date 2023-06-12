require 'test_helper'

class GitTreeTest < ActiveSupport::TestCase
  setup do
    @resource = FactoryBot.create(:ro_crate_git_workflow)
    @git_version = @resource.git_version
  end

  test 'root' do
    root = @git_version.tree

    assert root

    assert_equal '/', root.path

    assert_equal 4, root.blobs.count
    assert_equal 1, root.trees.count

    assert root.get_blob('LICENSE').is_a?(Git::Blob)
    assert root.get_tree('test').is_a?(Git::Tree)

    assert_equal 'test', root.absolute_path('test')
  end

  test 'nested' do
    tree = @git_version.get_tree('test')

    assert tree

    assert_equal 'test', tree.path

    assert_equal 0, tree.blobs.count
    assert_equal 1, tree.trees.count

    assert_nil tree.get_blob('LICENSE')
    assert tree.get_tree('test1').is_a?(Git::Tree)

    assert_equal 'test/test1', tree.absolute_path('test1')

    nested_tree = tree.get_tree('test1')

    assert nested_tree

    assert_equal 'test1', nested_tree.path

    assert_equal 3, nested_tree.blobs.count
    assert_equal 0, nested_tree.trees.count

    assert nested_tree.get_blob('input.bed').is_a?(Git::Blob)
    assert_nil nested_tree.get_tree('test')

    assert_equal 'test1/input.bed', nested_tree.absolute_path('input.bed')
  end
end
