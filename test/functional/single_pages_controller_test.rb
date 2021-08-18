require "test_helper"
class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    login_as @member
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      get :show, params: { id: project.id }
      assert_response :success
    end
  end

  test 'should redirect if not enabled' do
    with_config_value(:project_single_page_enabled, false) do
      project = Factory(:project)
      get :show,  params: { id: project.id }
      assert_redirected_to project_path(project)
    end
  end

  test 'should show the investigation content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      get :render_item_detail, xhr: true, params: { id: investigation.id, type: "investigation" }
      assert_response :success
      assert @response.body.include?('contribution-header')
      assert @response.body.include?('box_about_actor')
      assert @response.body.include?('Creators and Submitter')
      assert @response.body.include?('Activity')
      assert @response.body.include?('related-items')
      assert_equal investigation, assigns(:investigation)
    end
  end

  test 'should show the study content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      get :render_item_detail, xhr: true, params: { id: study.id, type: "study" }
      assert_response :success
      assert @response.body.include?('contribution-header')
      assert @response.body.include?('box_about_actor')
      assert @response.body.include?('Creators and Submitter')
      assert @response.body.include?('Activity')
      assert @response.body.include?('related-items')
      assert_equal study, assigns(:study)
    end
  end

  test 'should show the assay content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      assay = Factory(:assay, study: study)
      get :render_item_detail, xhr: true, params: { id: assay.id, type: "assay" }
      assert_response :success
      assert @response.body.include?('contribution-header')
      assert @response.body.include?('box_about_actor')
      assert @response.body.include?('Creators and Submitter')
      assert @response.body.include?('Activity')
      assert @response.body.include?('related-items')
      assert_equal assay, assigns(:assay)
      assert_equal assay, assigns(:asset)
    end
  end

  test 'should show the samples content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      sample = Factory(:sample)
      assay = Factory(:assay, study: study, sample_ids: [sample.id])
      
      ["resource-default-view","resource-condensed-view","resource-table-view"].each do |v|
        get :render_item_detail, xhr: true, params: { id: assay.id, type: "assay", view: v }
        assert_response :success
        assert @response.body.include?(v)
        assert_equal assay, assigns(:assay)
        assert_equal assay, assigns(:asset)
      end     
    end
  end

  test 'should show the data file content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      data_file = Factory(:data_file, contributor: User.current_user.person)
      assay = Factory(:assay, study: study, data_files: [data_file])
      get :render_item_detail, xhr: true, params: { id: assay.id, type: "assay", asset_id: data_file.id, asset_type: "data_file"  }
      assert_response :success
      assert @response.body.include?("contribution-header")
      assert @response.body.include?("box_about_actor")
      assert @response.body.include?("Version History")
      assert @response.body.include?("Tags")
      assert @response.body.include?("Attributions")
      assert_equal data_file, assigns(:data_file)
      assert_equal data_file, assigns(:asset)
    end
  end

  test 'should show the sop content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      sop = Factory(:sop, contributor: User.current_user.person)
      assay = Factory(:assay, study: study, sops: [sop])
      get :render_item_detail, xhr: true, params: { id: assay.id, type: "assay", asset_id: sop.id, asset_type: "sop"  }
      assert_response :success
      assert @response.body.include?("contribution-header")
      assert @response.body.include?("box_about_actor")
      assert @response.body.include?("Version History")
      assert @response.body.include?("Tags")
      assert @response.body.include?("Attributions")
      assert_equal sop, assigns(:sop)
      assert_equal sop, assigns(:asset)
    end
  end

  test 'should show the document content' do
    with_config_value(:project_single_page_enabled, true) do
      project = Factory(:project)
      investigation = Factory(:investigation, project_ids: [project.id])
      study = Factory(:study, investigation: investigation)
      document = Factory(:document, contributor: User.current_user.person)
      assay = Factory(:assay, study: study, documents: [document])
      get :render_item_detail, xhr: true, params: { id: assay.id, type: "assay", asset_id: document.id, asset_type: "document"  }
      assert_response :success
      assert @response.body.include?("contribution-header")
      assert @response.body.include?("box_about_actor")
      assert @response.body.include?("Version History")
      assert @response.body.include?("Tags")
      assert @response.body.include?("Attributions")
      assert_equal document, assigns(:document)
      assert_equal document, assigns(:asset)
    end
  end
  
end
