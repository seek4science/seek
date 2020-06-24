require "test_helper"
class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  # test "routes" do
  #   assert_generates "/single_pages/1/render_sharing_form/1/type/study", controller: "single_pages", action: "render_sharing_form", id: 1, type: "study"
  # end

  test 'should show' do
    project = Factory(:project)
    get :show, params: { id: project.id }
    assert_response :success
  end

  test 'should redirect if not enabled' do
    with_config_value(:project_single_page_enabled, false) do
      project = Factory(:project)
      get :show,  params: { id: project.id }
      assert_redirected_to project_path(project)
    end
  end

  test 'should prepare assets for sharing form' do
    project = Factory(:project)
    investigation = Factory(:investigation)
    study = Factory(:study)
    assay = Factory(:assay, assay_assets: [Factory(:assay_asset, asset:Factory(:sop))])

    get :render_sharing_form , params: { id: investigation.id, type: "investigation" }, format: :js 
    assert_response :success
    get :render_sharing_form , params: { id: study.id, type: "study" }, format: :js 
    assert_response :success
    get :render_sharing_form , params: { id: assay.id, type: "assay" }, format: :js 
    assert_response :success
    get :render_sharing_form , params: { id: -1, type: "assay" }, format: :js 
    assert_response :unprocessable_entity
    
  end


  test 'should create flowchart if not exist' do
    project = Factory(:project)
    study = Factory(:study)
    items = { id: 1, left: 2, top: 3 }
    flowchart = { study_id: study.id, items: JSON.generate(items)}
    post :update_flowchart, params: { id: project.id, flowchart: flowchart } 
    body = JSON.parse(response.body)
    assert body.include?('data')
    assert body['data'].include?('id')
    assert_equal body['is_new'], true
  end

  test 'should update flowchart' do
    project = Factory(:project)
    flowchart = Factory(:flowchart)
    items = { id: 2, left: 3, top: 4 }
    new_flowchart = { study_id: flowchart.study_id, items: JSON.generate(items)}
    post :update_flowchart, params: { id: project.id, flowchart: new_flowchart } 
    body = JSON.parse(response.body)
    assert body.include?('data')
    assert body['data'].include?('id')
    assert_equal body['is_new'], false
    assert_equal body['data']['items'], JSON.generate(items)
  end


  test 'should return error when no flowchart' do
    project = Factory(:project)
    study = Factory(:study)
    get :flowchart, params: { id: project.id, study_id: study.id }
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body.include?('error')
    assert_equal body['error'], 'no flowchart'
  end

  test 'should return flowchart' do
    project = Factory(:project)
    flowchart = Factory(:flowchart)
    get :flowchart, params: { id: project.id, study_id: flowchart.study_id }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.include?('data')
    assert body['data'].include?('operators')
    assert body['data'].include?('links')
    assert_equal body['data']['links'].length, 1
    assert_equal body['data']['operators'].length, 2
  end

end
