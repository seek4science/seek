require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
   fixtures :all
   include AuthenticatedTestHelper


 test 'create node' do
   node_text = 'test node text'
   node_type = 'prj'
   node_count = '7'
   node_id = '10'
   node_style = 'font-weight:bold'
   node_label = 'test label'
   node_action = '#'
   node_state_opened = true

   assert_equal @controller.send(:create_node, node_text, node_type, node_count, node_id, { style: node_style}, node_state_opened, node_label, node_action, nil), 
   {:text=>node_text, :_type=>node_type, :_id=>node_id, :a_attr=>{:style=>node_style}, :count=>node_count,
    :state=>{:opened=>node_state_opened, :separate=>{:label=>node_label, :action=>node_action}}}

 end

 test 'remove empty keys when create node' do
   node_text = 'test node text'
   node_type = 'prj'
   assert_equal @controller.send(:create_node, node_text, node_type), {:text=>node_text, :_type=>node_type, :state=>{:opened=>true}}
 end

 
 test 'upload file to project default folders' do
   assert_difference('OtherProjectFile.count', 1) do
      p = Factory(:project)
     post :upload_project_file , params: {id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file}
   end
 end

 test 'files count of project default folders' do
   p = Factory(:project)
   post :upload_project_file , params: {id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file}
   @controller.instance_variable_set(:@PFiles, p.other_project_files)
   assert_equal @controller.send(:f_count, 'presentations').to_i, 1 
 end

 test 'build tree data' do
   p = Factory(:project)
   i = Factory(:investigation, projects:[p])
   s = Factory(:study,investigation: i)
   a = Factory(:assay, study: s)
   @controller.instance_variable_set(:@project, p)
   @controller.instance_variable_set(:@PFiles, p.other_project_files)
   result = @controller.send(:build_tree_data)
   assert_instance_of Array, JSON.parse(result)
 end

 test 'get file list of project default folders' do
   p = Factory(:project)
   post :upload_project_file , params: {id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file}
   post :get_file_list , params: {id: p.id, folder: 'presentations'}
   result = JSON.parse(response.body)
   assert_equal result.length, 1 
   assert_equal result[0]["name"], "TestUpload.txt"
   assert_equal result[0]["extension"], ".txt"
end
   

test 'update_investigation_permission' do
   p = Factory(:project)
   u = Factory(:person)
   i = Factory(:investigation, projects:[p], contributor: u)
   login_as(u.user)
   @controller.instance_variable_set(:@investigation, i)
   post :update_investigation_permission , params: {id: p.id, inv_id: i.id, 'investigation[project_ids]': p.id,
       'policy_attributes[access_type]': '0',
       'policy_attributes[permissions_attributes][0][contributor_type]': 'Project', 
       'policy_attributes[permissions_attributes][0][contributor_id]': p.id,
       'policy_attributes[permissions_attributes][0][access_type]': 0,
       'policy_attributes[permissions_attributes][1][contributor_type]': 'Person',
       'policy_attributes[permissions_attributes][1][contributor_id]': u.id,
       'policy_attributes[permissions_attributes][1][access_type]': 0}
   result = JSON.parse(response.body)["message"]
   assert_equal result, "Permission was successfully updated"
end

test 'update_study_permission' do
   p = Factory(:project)
   u = Factory(:person, project: p)
   i = Factory(:investigation, projects:[p], contributor: u)
   s = Factory(:study,investigation: i, contributor: u)
   login_as(u.user)
   post :update_study_permission , params: {id: p.id, std_id: s.id,
       'policy_attributes[access_type]': '0',
       'policy_attributes[permissions_attributes][0][contributor_type]': 'Project', 
       'policy_attributes[permissions_attributes][0][contributor_id]': p.id,
       'policy_attributes[permissions_attributes][0][access_type]': 0,
       'policy_attributes[permissions_attributes][1][contributor_type]': 'Person',
       'policy_attributes[permissions_attributes][1][contributor_id]': u.id,
       'policy_attributes[permissions_attributes][1][access_type]': 0}
   result = JSON.parse(response.body)["message"]
   assert_equal result, "Permission was successfully updated"
end


 def uploadable_file
   fixture_file_upload('files/TestUpload.txt','text/plain')
 end
 
end