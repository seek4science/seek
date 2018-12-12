require 'test_helper'

class NodeTest < ActiveSupport::TestCase
  test 'validations' do
    node = Factory :node
    node.title = ''

    assert !node.valid?

    node.reload

  end

  test "new node's version is 1" do
    node = Factory :node
    assert_equal 1, node.version
  end

  test 'can create new version of node' do
    node = Factory :node
    old_attrs = node.attributes

    disable_authorization_checks do
      node.save_as_new_version('new version')
    end

    assert_equal 1, old_attrs['version']
    assert_equal 2, node.version

    old_attrs.delete('version')
    new_attrs = node.attributes
    new_attrs.delete('version')

    old_attrs.delete('updated_at')
    new_attrs.delete('updated_at')

    old_attrs.delete('created_at')
    new_attrs.delete('created_at')

    assert_equal old_attrs, new_attrs
  end

  test 'has uuid' do
    node = Factory :node
    assert_not_nil node.uuid
  end

end
