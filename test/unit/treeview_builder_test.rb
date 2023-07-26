require 'test_helper'

class TreeviewBuilderTest < ActionController::TestCase
  fixtures :all
  include ActionView::Helpers::SanitizeHelper

  test 'create node' do
    p = FactoryBot.create(:project)
    f = FactoryBot.create :project_folder, project_id: p.id
    node_text = 'test node text'
    node_type = 'prj'
    node_count = '7'
    node_id = '10'
    node_style = 'font-weight:bold'
    node_label = 'test label'
    node_state_opened = true

    controller = TreeviewBuilder.new p, [f]

    assert_equal controller.send(:create_node, { text: node_text, _type: node_type, count: node_count, resource: p,
                                                 _id: node_id, a_attr: { style: node_style }, opened: node_state_opened, label: node_label }),
                 text: node_text, a_attr: { style: node_style }, count: node_count, data: { id: node_id, type: node_type },
                 state: { opened: true, separate: { label: node_label } },
                 icon: '/assets/avatars/avatar-project.png'
  end

  test 'remove empty keys when create node' do
    p = FactoryBot.create(:project)
    f = FactoryBot.create :project_folder, project_id: p.id

    node_text = 'test node text'
    node_type = 'prj'
    controller = TreeviewBuilder.new p, [f]
    assert_equal controller.send(:create_node, { text: node_text, _type: node_type, resource: p }),
                 text: node_text, data: { type: node_type }, state: { opened: true },
                 icon: '/assets/avatars/avatar-project.png'
  end

  test 'build tree data with default root folder' do
    p = FactoryBot.create(:project)
    f = FactoryBot.create :project_folder, project_id: p.id
    i = FactoryBot.create(:investigation, projects: [p])
    s = FactoryBot.create(:study, investigation: i)
    FactoryBot.create(:assay, study: s)
    controller = TreeviewBuilder.new p, [f]
    result = controller.send(:build_tree_data)
    assert_instance_of Array, JSON.parse(result)
  end

  test 'build tree data with folders' do
    p = FactoryBot.create(:project)
    f = FactoryBot.create :project_folder, project_id: p.id
    sop = FactoryBot.create :sop, project_ids: [p.id], policy: FactoryBot.create(:public_policy)
    f.add_assets(sop)
    f.save!

    i = FactoryBot.create(:investigation, projects: [p])
    s = FactoryBot.create(:study, investigation: i)
    FactoryBot.create(:assay, study: s)

    controller = TreeviewBuilder.new p, [f]
    with_config_value(:project_single_page_folders_enabled, true) do
      result = controller.send(:build_tree_data)
      assert_instance_of Array, JSON.parse(result)
      assert_equal "folder", JSON.parse(result)[0]["children"][0]["data"]["type"]
    end
    result = controller.send(:build_tree_data)
    assert_equal "investigation", JSON.parse(result)[0]["children"][0]["data"]["type"]
  end

  test 'should sanitize the titles' do
    project = FactoryBot.create(:project)
    FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy),
                            title: '<style><script></style>alert("XSS");<style><</style>/</style><style>script></style>',
                            projects: [project])

    controller = TreeviewBuilder.new project, nil
    result = controller.send(:build_tree_data)
    text = JSON.parse(result)[0]['children'][0]['text']

    assert_equal '&lt;script&gt;alert("XSS");&lt;/script&gt;', text
  end
end
