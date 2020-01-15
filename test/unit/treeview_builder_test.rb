require 'test_helper'

class TreeviewBuilderTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper

  test 'create node' do
    p = Factory(:project)
    node_text = 'test node text'
    node_type = 'prj'
    node_count = '7'
    node_id = '10'
    node_style = 'font-weight:bold'
    node_label = 'test label'
    node_action = '#'
    node_state_opened = true

    controller = TreeviewBuilder.new p
    assert_equal controller.send(:create_node, node_text, node_type, node_count, node_id, { style: node_style }, node_state_opened, node_label, node_action, nil),
                 text: node_text, _type: node_type, _id: node_id, a_attr: { style: node_style }, count: node_count,
                 state: { opened: node_state_opened, separate: { label: node_label, action: node_action } }
  end

  test 'remove empty keys when create node' do
    p = Factory(:project)
    node_text = 'test node text'
    node_type = 'prj'
    controller = TreeviewBuilder.new p
    assert_equal controller.send(:create_node, node_text, node_type), text: node_text, _type: node_type, state: { opened: true }
  end

  test 'build tree data' do
    p = Factory(:project)
    i = Factory(:investigation, projects: [p])
    s = Factory(:study, investigation: i)
    a = Factory(:assay, study: s)
    controller = TreeviewBuilder.new p
    result = controller.send(:build_tree_data)
    assert_instance_of Array, JSON.parse(result)
  end
end
