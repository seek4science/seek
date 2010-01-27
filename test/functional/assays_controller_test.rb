require 'test_helper'

class AssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test "should show item" do
    get :show, :id=>assays(:metabolomics_assay)
    assert_response :success
    assert_not_nil assigns(:assay)

    assert_select "p#culture_growth_type",:text=>/Chemostat/,:count=>1
    assert_select "p#assay_type",:text=>/Metabalomics/,:count=>1
    assert_select "p#technology_type",:text=>/Gas chromatography/,:count=>1
  end

  test "show culture growth type not specified" do
    get :show, :id=>assays(:metabolomics_assay2)
    assert_response :success
    assert_not_nil assigns(:assay)

    assert_select "p#culture_growth_type",:text=>/Not specified/,:count=>1    
  end

  test "should show new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_nil assigns(:assay).study
  end

  test "should show new with study when id provided" do
    s=studies(:metabolomics_study)
    get :new,:study_id=>s
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_equal s,assigns(:assay).study
  end

  test "should show item with no study" do
    get :show, :id=>assays(:assay_with_no_study_or_files)
    assert_response :success
    assert_not_nil assigns(:assay)
  end

  test "should update with study" do
    a=assays(:assay_with_no_study_or_files)
    s=studies(:metabolomics_study)
    put :update,:id=>a,:assay=>{:study=>s}
    assert_redirected_to assay_path(a)
    assert assigns(:assay)
    assert_not_nil assigns(:assay).study
    assert_equal s,assigns(:assay).study
  end

  test "should create" do
    assert_difference("Assay.count") do
      post :create,:assay=>{:title=>"test",
                            :organism_id=>organisms(:yeast).id,
                            :technology_type_id=>technology_types(:gas_chromatography).id,
                            :assay_type_id=>assay_types(:metabolomics).id,
                            :study_id=>studies(:metabolomics_study).id}
    end
    a=assigns(:assay)
    assert_redirected_to assay_path(a)
    assert_equal organisms(:yeast),a.organism
  end

  test "should delete unlinked assay" do
    assert_difference('Assay.count', -1) do
      delete :destroy, :id => assays(:assay_with_no_study_or_files).id
    end
    assert !flash[:error]
    assert_redirected_to assays_path
  end

  test "should delete assay with study" do
    login_as(:model_owner)
    assert_difference('Assay.count',-1) do
      delete :destroy, :id => assays(:assay_with_just_a_study).id
    end
    assert_nil flash[:error]
    assert_redirected_to assays_path
  end

  test "should not delete assay when not project member" do
    login_as(:aaron)
    assert_no_difference('Assay.count') do
      delete :destroy, :id => assays(:assay_with_just_a_study).id
    end
    assert flash[:error]
    assert_redirected_to assays_path
  end

  test "should not delete assay with files" do
    assert_no_difference('Assay.count') do
      delete :destroy, :id => assays(:assay_with_no_study_but_has_some_files).id
    end
    assert flash[:error]
    assert_redirected_to assays_path
  end

  test "should not delete assay with sops" do
    assert_no_difference('Assay.count') do
      delete :destroy, :id => assays(:assay_with_no_study_but_has_some_sops).id
    end
    assert flash[:error]
    assert_redirected_to assays_path
  end

  test "data file list should only include those from project" do
    login_as(:model_owner)
    get :new    
    assert_select "select#possible_data_files" do
      assert_select "option",:text=>/Sysmo Data File/,:count=>1      
      assert_select "option",:text=>/Myexperiment Data File/,:count=>0
    end
  end

  test "download link for sop in tab has version" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)   

    assert_response :success
    
    assert_select "div.list_item div.list_item_actions" do
      path=download_sop_path(sops(:my_first_sop),:version=>1)
      assert_select "a[href=?]",path,:minumum=>1      
    end
  end

  test "show link for sop in tab has version" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)
    assert_response :success
    
    assert_select "div.list_item div.list_item_actions" do
      path=sop_path(sops(:my_first_sop),:version=>1)
      assert_select "a[href=?]",path,:minumum=>1
    end
  end

  test "edit link for sop in tabs" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)
    assert_response :success
    
    assert_select "div.list_item div.list_item_actions" do
      path=edit_sop_path(sops(:my_first_sop))
      assert_select "a[href=?]",path,:minumum=>1
    end
  end

  test "download link for data_file in tabs" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)
    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=download_data_file_path(data_files(:picture),:version=>1)
      assert_select "a[href=?]",path,:minumum=>1
    end
  end

  test "show link for data_file in tabs" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)
    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=data_file_path(data_files(:picture),:version=>1)
      assert_select "a[href=?]",path,:minumum=>1
    end
  end

  test "edit link for data_file in tabs" do
    login_as(:owner_of_my_first_sop)
    get :show,:id=>assays(:metabolomics_assay)
    assert_response :success

    assert_select "div.list_item div.list_item_actions" do
      path=edit_data_file_path(data_files(:picture))
      assert_select "a[href=?]",path,:minumum=>1
    end
  end

  test "links have nofollow in sop tabs" do
    login_as(:owner_of_my_first_sop)
    sop_version=sops(:my_first_sop).find_version(1)
    sop_version.description="http://news.bbc.co.uk"
    sop_version.save!

    get :show,:id=>assays(:metabolomics_assay)
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    login_as(:owner_of_my_first_sop)
    data_file_version=data_files(:picture).find_version(1)
    data_file_version.description="http://news.bbc.co.uk"
    data_file_version.save!

    get :show,:id=>assays(:metabolomics_assay)
    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]","nofollow",:text=>/news\.bbc\.co\.uk/,:minimum=>1
    end
  end

  
  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> assays(:assay_with_links_in_description)    
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  #checks that for an assay that has 2 sops and 2 datafiles, of which 1 is public and 1 private - only links to the public sops & datafiles are show
  def test_authorization_of_sops_and_datafiles_links
    #sanity check the fixtures are correct
    check_fixtures_for_authorization_of_sops_and_datafiles_links
    login_as(:model_owner)
    assay=assays(:assay_with_public_and_private_sops_and_datafiles)
    get :show,:id=>assay.id
    assert_response :success
    
    assert_select "div.tabbertab" do
      assert_select "h3",:text=>"SOPs (1)",:count=>1
      assert_select "h3",:text=>"SOPs (2)",:count=>0
      assert_select "h3",:text=>"Data Files (1)",:count=>1
      assert_select "h3",:text=>"Data Files (1)",:count=>1
    end

    assert_select "div.list_item" do
      assert_select "p.list_item_title a[href=?]",sop_path(sops(:sop_with_fully_public_policy),:version=>1),:text=>"SOP with fully public policy",:count=>1
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_fully_public_policy),:version=>1),:count=>1
      assert_select "p.list_item_title a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing),:version=>1),:count=>0
      assert_select "div.list_item_actions a[href=?]",sop_path(sops(:sop_with_private_policy_and_custom_sharing),:version=>1),:count=>0

      assert_select "p.list_item_title a[href=?]",data_file_path(data_files(:downloadable_data_file),:version=>1),:text=>"Download Only",:count=>1
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:downloadable_data_file),:version=>1),:count=>1
      assert_select "p.list_item_title a[href=?]",data_file_path(data_files(:private_data_file),:version=>1),:count=>0
      assert_select "div.list_item_actions a[href=?]",data_file_path(data_files(:private_data_file),:version=>1),:count=>0
    end

  end

  def check_fixtures_for_authorization_of_sops_and_datafiles_links
    user=users(:model_owner)
    assay=assays(:assay_with_public_and_private_sops_and_datafiles)
    assert_equal 4,assay.assets.size
    assert_equal 2,assay.sops.size
    assert_equal 2,assay.data_files.size
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).find_version(1))
    assert assay.sops.include?(sops(:sop_with_private_policy_and_custom_sharing).find_version(1))
    assert assay.data_files.include?(data_files(:downloadable_data_file).find_version(1))
    assert assay.data_files.include?(data_files(:private_data_file).find_version(1))

    assert Authorization.is_authorized?("show",nil,sops(:sop_with_fully_public_policy),user)
    assert !Authorization.is_authorized?("show",nil,sops(:sop_with_private_policy_and_custom_sharing),user)
    assert Authorization.is_authorized?("show",nil,data_files(:downloadable_data_file),user)
    assert !Authorization.is_authorized?("show",nil,data_files(:private_data_file),user)
  end
  
end
