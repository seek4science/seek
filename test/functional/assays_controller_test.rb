require 'test_helper'


class AssaysControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include FunctionalAuthorizationTests

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=Factory(:experimental_assay, :policy => Factory(:public_policy))
  end

  test "modelling assay validates with schema" do
    df = Factory(:data_file,:contributor=>User.current_user.person)
    a = Factory(:modelling_assay,:contributor=>User.current_user.person)
    disable_authorization_checks do
      a.relate(df)
      a.reload
    end

    User.with_current_user(a.study.investigation.contributor) { a.study.investigation.projects << Factory(:project) }
    assert_difference('ActivityLog.count') do
      get :show, :id=>a, :format=>"xml"
    end

    assert_response :success

    validate_xml_against_schema(@response.body)
  end

  test "check SOP and DataFile drop down contents" do
    user = Factory :user
    project=user.person.projects.first
    login_as user
    sop = Factory :sop, :contributor=>user.person,:project_ids=>[project.id]
    data_file = Factory :data_file, :contributor=>user.person,:project_ids=>[project.id]
    get :new, :class=>"experimental"
    assert_response :success

    assert_select "select#possible_data_files" do
      assert_select "option[value=?]",data_file.id,:text=>/#{data_file.title}/
      assert_select "option",:text=>/#{sop.title}/,:count=>0
    end

    assert_select "select#possible_sops" do
      assert_select "option[value=?]",sop.id,:text=>/#{sop.title}/
      assert_select "option",:text=>/#{data_file.title}/,:count=>0
    end
  end

  test "index includes modelling validates with schema" do
    get :index, :page=>"all", :format=>"xml"
    assert_response :success
    assays=assigns(:assays)
    assert assays.include?(assays(:modelling_assay_with_data_and_relationship)), "This test is invalid as the list should include the modelling assay"

    validate_xml_against_schema(@response.body)
  end

  test "shouldn't show unauthorized assays" do
    login_as Factory(:user)
    hidden = Factory(:experimental_assay, :policy => Factory(:private_policy)) #ensure at least one hidden assay exists
    get :index, :page=>"all", :format=>"xml"
    assert_response :success
    assert_equal assigns(:assays).sort_by(&:id), Assay.authorize_asset_collection(assigns(:assays), "view", users(:aaron)).sort_by(&:id), "#{t('assays.assay').downcase.pluralize} haven't been authorized"
    assert !assigns(:assays).include?(hidden)
  end

  def test_title
    get :index
    assert_select "title", :text=>/#{Seek::Config.application_title} #{I18n.t('assays.assay')}s.*/i, :count=>1
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test "should show draggable icon in index" do
    get :index
    assert_response :success
    assays = assigns(:assays)
    first_assay = assays.first
    assert_not_nil first_assay
    assert_select "a[id*=?]", /drag_Assay_#{first_assay.id}/
  end

  test "should show index in xml" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assays)
  end

  test "should update assay with new version of same sop" do
    login_as(:model_owner)
    assay=assays(:metabolomics_assay)
    timestamp=assay.updated_at

    sop = sops(:sop_with_all_sysmo_users_policy)
    assert !assay.sops.include?(sop.latest_version)
    assert_difference('ActivityLog.count') do
      put :update, :id=>assay, :assay_sop_ids=>[sop.id], :assay=>{}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)

    assay.reload
    stored_sop = assay.assay_assets.detect { |aa| aa.asset_id=sop.id }.versioned_asset
    assert_equal sop.version, stored_sop.version

    login_as sop.contributor
    sop.save_as_new_version
    login_as(:model_owner)

    assert_difference('ActivityLog.count') do
      put :update, :id=>assay, :assay_sop_ids=>[sop.id], :assay=>{}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assay.reload
    stored_sop = assay.assay_assets.detect { |aa| aa.asset_id=sop.id }.versioned_asset
    assert_equal sop.version, stored_sop.version


  end

  test "should update timestamp when associating sop" do
    login_as(:model_owner)
    assay=assays(:metabolomics_assay)
    timestamp=assay.updated_at

    sop = sops(:sop_with_all_sysmo_users_policy)
    assert !assay.sops.include?(sop.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>assay, :assay_sop_ids=>[sop.id], :assay=>{}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay=Assay.find(assay.id)
    assert updated_assay.sops.include?(sop.latest_version)
    assert_not_equal timestamp, updated_assay.updated_at

  end


  test "should update timestamp when associating datafile" do
    login_as(:model_owner)
    assay=assays(:metabolomics_assay)
    timestamp=assay.updated_at

    df = data_files(:downloadable_data_file)
    assert !assay.data_files.include?(df.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>assay, :data_file_ids=>["#{df.id},Test data"], :assay=>{}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay=Assay.find(assay.id)
    assert updated_assay.data_files.include?(df.latest_version)
    assert_not_equal timestamp, updated_assay.updated_at
  end

  test "should update timestamp when associating model" do
    login_as(:model_owner)
    assay=assays(:metabolomics_assay)
    timestamp=assay.updated_at

    model = models(:teusink)
    assert !assay.models.include?(model.latest_version)
    sleep(1)
    assert_difference('ActivityLog.count') do
      put :update, :id=>assay, :model_ids=>[model.id], :assay=>{}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to assay_path(assay)
    assert assigns(:assay)
    updated_assay=Assay.find(assay.id)
    assert updated_assay.models.include?(model.latest_version)
    assert_not_equal timestamp, updated_assay.updated_at
  end

  test "should show item" do
    assay = Factory(:experimental_assay,:policy=>Factory(:public_policy),
                    :assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Catabolic_response",
                    :technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Binding")
    assert_difference('ActivityLog.count') do
      get :show, :id=>assay.id
    end

    assert_response :success

    assert_not_nil assigns(:assay)

    assert_select "p#assay_type", :text=>/Catabolic response/, :count=>1
    assert_select "p#technology_type", :text=>/Binding/, :count=>1
  end

  test "should not show tagging when not logged in" do
    logout
    public_assay = Factory(:experimental_assay, :policy => Factory(:public_policy))
    get :show, :id=>public_assay
    assert_response :success
    assert_select "div#tags_box", :count=>0
  end

  test "should show modelling assay" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>assays(:modelling_assay_with_data_and_relationship)
    end

    assert_response :success
    assert_not_nil assigns(:assay)
    assert_equal assigns(:assay), assays(:modelling_assay_with_data_and_relationship)
  end

  test "should show new" do
    #adding a suggested type tests the assay type tree handles inclusion of suggested type
    Factory :suggested_assay_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Catabolic_response"
    get :new
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_nil assigns(:assay).study
  end

  test "should show new with study when id provided" do
    s=studies(:metabolomics_study)
    get :new, :study_id=>s
    assert_response :success
    assert_not_nil assigns(:assay)
    assert_equal s, assigns(:assay).study
  end

  test "should show item with no study" do
    assert_difference('ActivityLog.count') do
      get :show, :id=>assays(:assay_with_no_study_or_files)
    end

    assert_response :success
    assert_not_nil assigns(:assay)
  end

  test "should update with study" do
    login_as(:model_owner)
    a=assays(:assay_with_no_study_or_files)
    s=studies(:metabolomics_study)
    assert_difference('ActivityLog.count') do
      put :update, :id=>a, :assay=>{:study_id=>s}, :assay_sample_ids=>[Factory(:sample).id]
    end

    assert_redirected_to assay_path(a)
    assert assigns(:assay)
    assert_not_nil assigns(:assay).study
    assert_equal s, assigns(:assay).study
  end


  test "should create experimental assay with or without sample" do
    organism = Factory(:organism,:title=>"Frog")
    strain = Factory(:strain, :title=>"UUU", :organism=>organism)
    assert_difference('ActivityLog.count') do
      assert_difference("Assay.count") do
        post :create, :assay => {:title => "test",
                                 :study_id => studies(:metabolomics_study).id,
                                 :assay_class_id => assay_classes(:experimental_assay_class).id
        }, :assay_organism_ids => [organism.id, strain.title, strain.id, ""].join(","), :sharing => valid_sharing
      end
    end
    a=assigns(:assay)
    assert a.samples.empty?


    sample = Factory(:sample)
    assert_difference('ActivityLog.count') do
      assert_difference("Assay.count") do
        post :create, :assay => {:title => "test",
                                 :study_id => studies(:metabolomics_study).id,
                                 :assay_class_id => assay_classes(:experimental_assay_class).id,
                                 :sample_ids => [sample.id]
        }, :sharing => valid_sharing

      end
    end
    a=assigns(:assay)
    assert_equal User.current_user.person, a.owner
    assert_redirected_to assay_path(a)
    assert_equal [sample], a.samples
  end

  test "should update assay with strains and organisms and sample" do
    assay = Factory(:assay,:contributor=>User.current_user.person)
    assert_empty assay.organisms
    assert_empty assay.strains
    assert_empty assay.samples


    organism = Factory(:organism,:title=>"Frog")
    strain = Factory(:strain, :title=>"UUU", :organism=>organism)
    sample = Factory(:sample)

    assert_difference("AssayOrganism.count") do
      put :update, :id=>assay.id,:assay => {:title => "test"},
                        :assay_organism_ids => [organism.id,strain.title, strain.id, ""].join(",")#,
                        # :sharing => valid_sharing

    end
    assay = assigns(:assay)
    assert_redirected_to assay_path(assay)
    assert_include assay.organisms,organism
    assert_include assay.strains,strain
  end



  test "should create modelling assay with/without organisms" do

    assert_difference("Assay.count") do
      post :create, :assay=>{:title=>"test",
                             :study_id=>studies(:metabolomics_study).id,
                             :assay_class_id=>assay_classes(:modelling_assay_class).id}, :sharing => valid_sharing
    end

    assay = assigns(:assay)
    refute_nil assay
    assert assay.organisms.empty?
    assert assay.strains.empty?

    organism = Factory(:organism,:title=>"Frog")
    strain = Factory(:strain, :title=>"UUU", :organism=>organism)
    growth_type = Factory(:culture_growth_type, :title=>"batch")
    assert_difference("Assay.count") do
      post :create, :assay=>{:title=>"test",
                             :study_id=>studies(:metabolomics_study).id,
                             :assay_class_id=>assay_classes(:modelling_assay_class).id},
           :assay_organism_ids => [organism.id, strain.title,strain.id, growth_type.title].join(","), :sharing => valid_sharing
    end
    a=assigns(:assay)
    assert_equal 1, a.assay_organisms.count
    assert_include a.organisms, organism
    assert_include a.strains,strain
    assert_redirected_to assay_path(a)


  end

  test "should not create modelling assay with sample" do
    person = Factory(:person)
    assert_no_difference("Assay.count") do
      post :create, :assay => {:title => "test",
                               :study_id => studies(:metabolomics_study).id,
                           :assay_class_id=>assay_classes(:modelling_assay_class).id,
                           :sample_ids=>[Factory(:sample).id, Factory(:sample).id].join(",")
                               },
                               :sharing => valid_sharing
    end
    assert_response :success
    assert assigns(:assay)
    assay = assigns(:assay)
    assert_equal 0, assay.samples.count
  end

  test "should create modelling assay with sample for virtual liver" do
    as_virtualliver do
      assert_difference("Assay.count") do
        post :create, :assay => {:title => "test",
                                 :study_id => studies(:metabolomics_study).id,
                                 :assay_class_id => assay_classes(:modelling_assay_class).id,
                                 :sample_ids => [Factory(:sample, :policy=>Factory(:public_policy)).id, Factory(:sample,:policy=>Factory(:public_policy)).id]},
                                 :sharing => valid_sharing
      end
      assert assigns(:assay)
      assay = assigns(:assay)
      assert_redirected_to assay_path(assay)
      assert_equal 2, assay.samples.count

    end

  end

  test "should create assay with ontology assay and tech type" do
    assert_difference("Assay.count") do
      post :create, :assay => {:title => "test",
                               :technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",
                               :assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",
                               :study_id => Factory(:study).id,
                               :assay_class_id => Factory(:experimental_assay_class).id},
           :sharing => valid_sharing
    end
    assert assigns(:assay)
    assay = assigns(:assay)
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",assay.technology_type_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",assay.assay_type_uri
    assert_equal "Gas chromatography",assay.technology_type_label
    assert_equal "Metabolomics",assay.assay_type_label
  end

  test "should create assay with suggested assay and tech type" do
    assay_type=Factory(:suggested_assay_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",:label=>"fish")
    tech_type=Factory(:suggested_technology_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",:label=>"carrot")
    assert_difference("Assay.count") do
      post :create, :assay => {:title => "test",
                               :technology_type_uri=>tech_type.uri,
                               :assay_type_uri=>assay_type.uri,
                               :study_id => Factory(:study).id,
                               :assay_class_id => Factory(:experimental_assay_class).id},
           :sharing => valid_sharing
    end
    assert assigns(:assay)
    assay = assigns(:assay)
    assert_equal assay_type,assay.suggested_assay_type
    assert_equal tech_type,assay.suggested_technology_type
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",assay.technology_type_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",assay.assay_type_uri
    assert_equal "carrot",assay.technology_type_label
    assert_equal "fish",assay.assay_type_label
  end

  test "should update assay with suggested assay and tech type" do
    assay = Factory(:experimental_assay,:contributor=>User.current_user.person)
    assay_type=Factory(:suggested_assay_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",:label=>"fish")
    tech_type=Factory(:suggested_technology_type,:ontology_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",:label=>"carrot")

    post :update, :id=>assay.id,:assay => {
                             :technology_type_uri=>tech_type.uri,
                             :assay_type_uri=>assay_type.uri
                             },
         :sharing => valid_sharing

    assay.reload
    assert_equal assay_type,assay.suggested_assay_type
    assert_equal tech_type,assay.suggested_technology_type
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",assay.technology_type_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",assay.assay_type_uri
    assert_equal "fish",assay.assay_type_label
    assert_equal "carrot",assay.technology_type_label
  end

  test "should delete assay with study" do
    a = assays(:assay_with_just_a_study)
    login_as(:model_owner)
    assert_difference('ActivityLog.count') do
      assert_difference('Assay.count', -1) do
        delete :destroy, :id => a
      end
    end

    assert_nil flash[:error]
    assert_redirected_to assays_path
  end

  test "should not delete assay when not project member" do
    a = assays(:assay_with_just_a_study)
    login_as(:aaron)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete assay when not project pal" do
    a = assays(:assay_with_just_a_study)
    login_as(:datafile_owner)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test "should list correct organisms" do
    a = Factory :assay,:policy=>Factory(:public_policy)
    o1 = Factory(:organism,:title=>"Frog")

    Factory :assay_organism, :assay=>a,:organism=>o1

    get :show,:id=>a.id
    assert_response :success

    assert_select "p#organism" do
      assert_select "a[href=?]",organism_path(o1),:text=>"Frog"
    end

    o2 = Factory(:organism,:title=>"Slug")
    str = Factory :strain, :title=>"AAA111", :organism=>o2
    Factory :assay_organism,:assay=>a,:organism=>o2,:strain=>str
    get :show,:id=>a.id
        assert_response :success
        assert_select "p#organism" do
          assert_select "a[href=?]",organism_path(o1),:text=>"Frog"
          assert_select "a[href=?]",organism_path(o2),:text=>"Slug"
          assert_select "span.strain_info",:text=>str.info
        end
  end

  test "should show edit when not logged in" do
    logout
    a = Factory :experimental_assay,:contributor=>Factory(:person),:policy=>Factory(:editing_public_policy)
    get :edit,:id=>a
    assert_response :success

    a = Factory :modelling_assay,:contributor=>Factory(:person),:policy=>Factory(:editing_public_policy)
    get :edit,:id=>a
    assert_response :success
  end

  test "should not show delete button if not authorized to delete but can edit" do
    person = Factory :person
    a = Factory :assay,:contributor=>person,:policy=>Factory(:public_policy,:access_type=>Policy::EDITING)
    assert !a.can_manage?
    assert a.can_view?
    get :show,:id=>a.id
    assert_response :success
    assert_select "ul.sectionIcons" do
      assert_select "li" do
        assert_select "span",:text=>/Delete/,:count=>0
      end
    end
  end

  test "should show delete button in disable state if authorized to delete but has associated items" do
    person = Factory :person
    a = Factory :assay,:contributor=>person,:policy=>Factory(:public_policy)
    df = Factory :data_file, :contributor=>person,:policy=>Factory(:public_policy)
    Factory :assay_asset,:assay=>a,:asset=>df
    a.reload
    assert a.can_manage?
    assert_equal 1,a.assets.count
    assert !a.can_delete?
    get :show,:id=>a.id
    assert_response :success
    assert_select "ul.sectionIcons" do
      assert_select "li" do
        assert_select "span.disabled_icon",:text=>/Delete/,:count=>1
      end
    end
  end

  test "should show delete button in enabled state if authorized delete and has no associated items" do
    person = Factory :person
    a = Factory :assay,:contributor=>person,:policy=>Factory(:public_policy)

    assert a.can_manage?
    assert a.can_delete?
    get :show,:id=>a.id
    assert_response :success
    assert_select "ul.sectionIcons" do
      assert_select "li" do
        assert_select "span",:text=>/Delete/,:count=>1
        assert_select "span.disabled_icon",:text=>/Delete/,:count=>0
      end
    end
  end

  test "should not edit assay when not project pal" do
    a = assays(:assay_with_just_a_study)
    login_as(:datafile_owner)
    get :edit, :id => a
    assert flash[:error]
    assert_redirected_to a
  end

  test "admin should not edit somebody elses assay" do
    a = assays(:assay_with_just_a_study)
    login_as(:quentin)
    get :edit, :id => a
    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete assay with data files" do
    login_as(:model_owner)
    a = assays(:assay_with_no_study_but_has_some_files)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end
    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete assay with model" do
    login_as(:model_owner)
    a = assays(:assay_with_a_model)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete assay with publication" do
    login_as(:model_owner)
    a = assays(:assay_with_a_publication)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test "should not delete assay with sops" do
    login_as(:model_owner)
    a = assays(:assay_with_no_study_but_has_some_sops)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete :destroy, :id => a
      end
    end

    assert flash[:error]
    assert_redirected_to a
  end

  test "get new presents options for class" do
    login_as(:model_owner)
    get :new
    assert_response :success
    assert_select "a[href=?]", new_assay_path(:class=>:experimental), :count=>1
    assert_select "a", :text=>/An #{I18n.t('assays.experimental_assay')}/i, :count=>1
    assert_select "a[href=?]", new_assay_path(:class=>:modelling), :count=>1
    assert_select "a", :text=>/A #{I18n.t('assays.modelling_analysis')}/i, :count=>1
  end

  test "get new with class doesnt present options for class" do
    login_as(:model_owner)
    get :new, :class=>"experimental"
    assert_response :success
    assert_select "a[href=?]", new_assay_path(:class=>:experimental), :count=>0
    assert_select "a", :text=>/An #{I18n.t('assays.experimental_assay')}/i, :count=>0
    assert_select "a[href=?]", new_assay_path(:class=>:modelling), :count=>0
    assert_select "a", :text=>/A #{I18n.t('assays.modelling_analysis')}/i, :count=>0

    get :new, :class=>"modelling"
    assert_response :success
    assert_select "a[href=?]", new_assay_path(:class=>:experimental), :count=>0
    assert_select "a", :text=>/An #{I18n.t('assays.experimental_assay')}/i, :count=>0
    assert_select "a[href=?]", new_assay_path(:class=>:modelling), :count=>0
    assert_select "a", :text=>/A #{I18n.t('assays.modelling_analysis')}/i, :count=>0
  end

  test "data file list should only include those from project" do
    login_as(:model_owner)
    get :new, :class=>"experimental"
    assert_response :success
    assert_select "select#possible_data_files" do
      assert_select "option", :text=>/Sysmo Data File/, :count=>1
      assert_select "option", :text=>/Myexperiment Data File/, :count=>0
    end
  end

  test "download link for sop in lazy loaded tab" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [sops(:my_first_sop).id].join(","), :resource_type => "Sop", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end
    assert_select "div.list_item div.list_item_actions" do
      path=download_sop_path(sops(:my_first_sop))
      assert_select "a[href=?]", path, :minumum => 1
    end
  end

  test "show link for sop in lazy loaded tab" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [sops(:my_first_sop).id].join(","), :resource_type => "Sop", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end
    assert_select "div.list_item div.list_item_actions" do
      path=sop_path(sops(:my_first_sop))
      assert_select "a[href=?]", path, :minumum => 1
    end
  end

  test "edit link for sop in lazy loaded tabs" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [sops(:my_first_sop).id].join(","), :resource_type => "Sop", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end
    assert_select "div.list_item div.list_item_actions" do
      path=edit_sop_path(sops(:my_first_sop))
      assert_select "a[href=?]", path, :minumum=>1
    end
  end

  test "download link for data_file in lazy loaded tabs" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [data_files(:picture).id].join(","), :resource_type => "DataFile", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end
    assert_select "div.list_item div.list_item_actions" do
    path=download_data_file_path(data_files(:picture))
    assert_select "a[href=?]", path, :minumum => 1
    end
  end

  test "show link for data_file in laz loaded tabs" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [data_files(:picture).id].join(","), :resource_type => "DataFile", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end
    assert_select "div.list_item div.list_item_actions" do
      path=data_file_path(data_files(:picture))
      assert_select "a[href=?]", path, :minumum => 1
    end
  end

  test "edit link for data_file in lazy loaded tabs" do
    login_as(:owner_of_my_first_sop)

    with_config_value :tabs_lazy_load_enabled, true do
      get :resource_in_tab, {:resource_ids => [data_files(:picture).id].join(","), :resource_type => "DataFile", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
    end

    assert_select "div.list_item div.list_item_actions" do
      path=edit_data_file_path(data_files(:picture))
      assert_select "a[href=?]", path, :minumum => 1
    end
  end

  test "links have nofollow in sop tabs" do
    login_as(:owner_of_my_first_sop)
    sop_version=sops(:my_first_sop)
    sop_version.description="http://news.bbc.co.uk"
    sop_version.save!
    assert_difference('ActivityLog.count') do
      get :show, :id=>assays(:metabolomics_assay)
    end

    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]", "nofollow", :text=>/news\.bbc\.co\.uk/, :minimum=>1
    end
  end

  test "links have nofollow in data_files tabs" do
    login_as(:owner_of_my_first_sop)
    data_file_version=data_files(:picture)
    data_file_version.description="http://news.bbc.co.uk"
    data_file_version.save!
    assert_difference('ActivityLog.count') do
      get :show, :id=>assays(:metabolomics_assay)
    end

    assert_select "div.list_item div.list_item_desc" do
      assert_select "a[rel=?]", "nofollow", :text=>/news\.bbc\.co\.uk/, :minimum=>1
    end
  end


  def test_should_add_nofollow_to_links_in_show_page
    assert_difference('ActivityLog.count') do
      get :show, :id=> assays(:assay_with_links_in_description)
    end

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
    assert_difference('ActivityLog.count') do
      get :show, :id=>assay.id
    end

    assert_response :success

    assert_select "div.tabbertab" do
      assert_select "h3", :text=>"#{I18n.t('sop').pluralize} (1+1)", :count=>1
      assert_select "h3", :text=>"#{I18n.t('data_file').pluralize} (1+1)", :count=>1
    end

    assert_select "div.list_item" do
      assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :text=>"SOP with fully public policy", :count=>1
      assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :count=>1
      assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count=>0
      assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count=>0

      assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:downloadable_data_file)), :text=>"Download Only", :count=>1
      assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:downloadable_data_file)), :count=>1
      assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:private_data_file)), :count=>0
      assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:private_data_file)), :count=>0
    end

  end

  def test_authorization_of_sops_and_datafiles_links_with_lazy_load
    #sanity check the fixtures are correct
    check_fixtures_for_authorization_of_sops_and_datafiles_links
    login_as(:model_owner)
    assay=assays(:assay_with_public_and_private_sops_and_datafiles)

    with_config_value :tabs_lazy_load_enabled, true do

      assert_difference('ActivityLog.count') do
        get :show, :id => assay.id
      end

      assert_response :success

      # tabs lazy loading: only first tab with items, and other tabs only item types and counts are shown.
      assert_select "div.tabbertab" do
        assert_select "h3", :text => "#{I18n.t('sop').pluralize} (2)", :count => 1
        assert_select "h3", :text => "#{I18n.t('data_file').pluralize} (2)", :count => 1
      end

      #Other items are only shown when the tab is clicked
      #TODO: better method to test clicking link?

      #assay.data_files is data_file_versions
      data_file_ids = assay.data_files.map &:data_file_id
      get :resource_in_tab, {:resource_ids => data_file_ids.join(","), :resource_type => "DataFile", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
      assert_response :success
      assert_select "div.list_item" do
        assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:downloadable_data_file)), :text => "Download Only", :count => 1
        assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:downloadable_data_file)), :count => 1
        assert_select "div.list_item_title a[href=?]", data_file_path(data_files(:private_data_file)), :count => 0
        assert_select "div.list_item_actions a[href=?]", data_file_path(data_files(:private_data_file)), :count => 0
      end

      sop_ids = assay.sops.map &:sop_id
      get :resource_in_tab, {:resource_ids => sop_ids.join(","), :resource_type => "Sop", :view_type => "view_some", :scale_title => "all", :actions_partial_disable => 'false'}
      assert_response :success
      assert_select "div.list_item" do
        assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :text => "SOP with fully public policy", :count => 1
        assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_fully_public_policy)), :count => 1
        assert_select "div.list_item_title a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count => 0
        assert_select "div.list_item_actions a[href=?]", sop_path(sops(:sop_with_private_policy_and_custom_sharing)), :count => 0
      end
    end
  end
  test "associated assets aren't lost on failed validation in create" do
    sop=sops(:sop_with_all_sysmo_users_policy)
    model=models(:model_with_links_in_description)
    datafile=data_files(:downloadable_data_file)
    rel=RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference("Assay.count", "Should not have added assay because the title is blank") do
        assert_no_difference("AssayAsset.count", "Should not have added assay assets because the assay validation failed") do
          #title is blank, so should fail validation
          post :create, :assay=>{
              :title=>"",
              :technology_type_uri=>"http://some-uri#tech",
              :assay_type_uri=>"http://some-uri#assay",
              :study_id=>studies(:metabolomics_study).id,
              :assay_class_id=>assay_classes(:modelling_assay_class).id
          }, :sharing => valid_sharing ,
               :assay_sop_ids=>["#{sop.id}"],
               :model_ids=>["#{model.id}"],
               :data_file_ids=>["#{datafile.id},#{rel.title}"]
        end
      end
    end


      #since the items are added to the UI by manipulating the DOM with javascript, we can't do assert_select on the HTML elements to check they are there.
      #so instead check for the relevant generated lines of javascript
    assert_select "script", :text=>/sop_title = '#{sop.title}'/, :count=>1
    assert_select "script", :text=>/sop_id = '#{sop.id}'/, :count=>1
    assert_select "script", :text=>/model_title = '#{model.title}'/, :count=>1
    assert_select "script", :text=>/model_id = '#{model.id}'/, :count=>1
    assert_select "script", :text=>/data_title = '#{datafile.title}'/, :count=>1
    assert_select "script", :text=>/data_file_id = '#{datafile.id}'/, :count=>1
    assert_select "script", :text=>/relationship_type = '#{rel.title}'/, :count=>1
    assert_select "script", :text=>/addDataFile/, :count=>1
    assert_select "script", :text=>/addSop/, :count=>1
    assert_select "script", :text=>/addModel/, :count=>1
  end

  test "should create with associated model sop data file and publication" do
    user = Factory :user
    login_as(user)
    sop=Factory :sop,:policy=>Factory(:public_policy),:contributor=>user
    model=Factory :model,:policy=>Factory(:public_policy),:contributor=>user
    df=Factory :data_file,:policy=>Factory(:public_policy),:contributor=>user
    pub=Factory :publication,:contributor=>user
    study=Factory :study, :policy=>Factory(:public_policy),:contributor=>user
    rel=RelationshipType.first

    assert_difference('ActivityLog.count') do
      assert_difference("Assay.count") do
        assert_difference("AssayAsset.count", 3) do
          assert_difference("Relationship.count") do

          post :create, :assay=>{
              :title=>"fish",
              :study_id=>study.id,
              :assay_class_id=>assay_classes(:modelling_assay_class).id
          },
               :assay_sop_ids=>["#{sop.id}"],
               :model_ids=>["#{model.id}"],
               :data_file_ids=>["#{df.id},#{rel.title}"],
               :related_publication_ids=>["#{pub.id}"],
               :sharing => valid_sharing # default policy is nil in VLN
          end
        end
      end
    end

    assert_not_nil assigns(:assay)
    assay = assigns(:assay)
    assay.reload #necessary to pickup the relationships for publications
    assert_equal [sop], assay.sop_masters
    assert_equal [df], assay.data_file_masters
    assert_equal [model],assay.model_masters
    assert_equal [pub], assay.related_publications

  end

  test "associated assets aren't lost on failed validation on update" do
    login_as(:model_owner)
    assay=assays(:assay_with_links_in_description)

      #remove any existing associated assets
    assay.assets.clear
    assay.save!
    assay.reload
    assert assay.sops.empty?
    assert assay.models.empty?
    assert assay.data_files.empty?

    sop=sops(:sop_with_all_sysmo_users_policy)
    model=models(:model_with_links_in_description)
    datafile=data_files(:downloadable_data_file)
    rel=RelationshipType.first

    assert_no_difference('ActivityLog.count') do
      assert_no_difference("Assay.count", "Should not have added assay because the title is blank") do
        assert_no_difference("AssayAsset.count", "Should not have added assay assets because the assay validation failed") do
          #title is blank, so should fail validation
          put :update, :id=>assay, :assay=>{:title=>"", :assay_class_id=>assay_classes(:modelling_assay_class).id},
              :assay_sop_ids=>["#{sop.id}"],
              :model_ids=>["#{model.id}"],
              :data_file_ids=>["#{datafile.id},#{rel.title}"]
        end
      end
    end


      #since the items are added to the UI by manipulating the DOM with javascript, we can't do assert_select on the HTML elements to check they are there.
      #so instead check for the relevant generated lines of javascript
    assert_select "script", :text=>/sop_title = '#{sop.title}'/, :count=>1
    assert_select "script", :text=>/sop_id = '#{sop.id}'/, :count=>1
    assert_select "script", :text=>/model_title = '#{model.title}'/, :count=>1
    assert_select "script", :text=>/model_id = '#{model.id}'/, :count=>1
    assert_select "script", :text=>/data_title = '#{datafile.title}'/, :count=>1
    assert_select "script", :text=>/data_file_id = '#{datafile.id}'/, :count=>1
    assert_select "script", :text=>/relationship_type = '#{rel.title}'/, :count=>1
    assert_select "script", :text=>/addDataFile/, :count=>1
    assert_select "script", :text=>/addSop/, :count=>1
    assert_select "script", :text=>/addModel/, :count=>1
  end

  def check_fixtures_for_authorization_of_sops_and_datafiles_links
    user=users(:model_owner)
    assay=assays(:assay_with_public_and_private_sops_and_datafiles)
    assert_equal 4, assay.assets.size
    assert_equal 2, assay.sops.size
    assert_equal 2, assay.data_files.size
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).find_version(1))
    assert assay.sops.include?(sops(:sop_with_private_policy_and_custom_sharing).find_version(1))
    assert assay.data_files.include?(data_files(:downloadable_data_file).find_version(1))
    assert assay.data_files.include?(data_files(:private_data_file).find_version(1))

    assert sops(:sop_with_fully_public_policy).can_view? user
    assert !sops(:sop_with_private_policy_and_custom_sharing).can_view?(user)
    assert data_files(:downloadable_data_file).can_view?(user)
    assert !data_files(:private_data_file).can_view?(user)
  end

  test "filtering by study" do
    study=studies(:metabolomics_study)
    get :index, :filter => {:study => study.id}
    assert_response :success
  end

  test "filtering by investigation" do
    inv=investigations(:metabolomics_investigation)
    get :index, :filter => {:investigation => inv.id}
    assert_response :success
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test "filtering by person" do
    person = people(:person_for_model_owner)
    get :index, :filter=>{:person=>person.id}, :page=>"all"
    assert_response :success
    a = assays(:metabolomics_assay)
    a2 = assays(:modelling_assay_with_data_and_relationship)
    assert_select "div.list_items_container" do
      assert_select "a", :text=>a.title, :count=>1
      assert_select "a", :text=>a2.title, :count=>0
    end
  end

  test 'edit assay with selected projects scope policy' do
    proj = User.current_user.person.projects.first
    assay = Factory(:assay, :contributor => User.current_user.person,
                    :study => Factory(:study, :investigation => Factory(:investigation, :project_ids => [proj.id])),
                    :policy => Factory(:policy,
                                       :sharing_scope => Policy::ALL_SYSMO_USERS,
                                       :access_type => Policy::NO_ACCESS,
                                       :permissions => [Factory(:permission, :contributor => proj, :access_type => Policy::EDITING)]))
    get :edit, :id => assay.id
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do
    login_as(:quentin)
    a = {:title=>"test",
         :study_id=>studies(:metabolomics_study).id,
         :assay_class_id=>assay_classes(:experimental_assay_class).id,
         :sample_ids=>[Factory(:sample).id]}
    assert_difference('ActivityLog.count') do
      assert_difference('Assay.count') do
        post :create, :assay => a, :sharing=>{"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::VISIBLE, :sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::ACCESSIBLE}
      end
    end

    assay=assigns(:assay)
    assert_redirected_to assay_path(assay)
    assert_equal Policy::ALL_SYSMO_USERS, assay.policy.sharing_scope
    assert_equal Policy::VISIBLE, assay.policy.access_type
    assert_equal assay.policy.permissions.count, 1

    assay.policy.permissions.each do |permission|
      assert_equal permission.contributor_type, 'Project'
      assert assay.study.investigation.project_ids.include?(permission.contributor_id)
      assert_equal permission.policy_id, assay.policy_id
      assert_equal permission.access_type, Policy::ACCESSIBLE
    end
  end

  test "should update sharing permissions 'with your project and with all SysMO members'" do
    login_as Factory(:user)
    assay= Factory(:assay,
                   :policy => Factory(:private_policy),
                   :contributor => User.current_user.person,
                   :study => (Factory(:study, :investigation => (Factory(:investigation,
                                                                         :project_ids => [Factory(:project).id, Factory(:project).id])))))

    assert assay.can_manage?
    assert_equal Policy::PRIVATE, assay.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, assay.policy.access_type
    assert assay.policy.permissions.empty?

    assert_difference('ActivityLog.count') do
      put :update, :id => assay, :assay => {}, :sharing => {"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::ACCESSIBLE, :sharing_scope => Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::EDITING}
    end

    assay.reload
    assert_redirected_to assay_path(assay)
    assert_equal Policy::ALL_SYSMO_USERS, assay.policy.sharing_scope
    assert_equal Policy::ACCESSIBLE, assay.policy.access_type
    assert_equal 2, assay.policy.permissions.length

    assay.policy.permissions.each do |update_permission|
      assert_equal update_permission.contributor_type, 'Project'
      assert assay.projects.map(&:id).include?(update_permission.contributor_id)
      assert_equal update_permission.policy_id, assay.policy_id
      assert_equal update_permission.access_type, Policy::EDITING
    end
  end

  test 'should have associated datafiles, models, on modelling assay show page' do
    df = Factory(:data_file,:contributor => User.current_user)
    model = Factory(:model,:contributor => User.current_user)
    assay= Factory(:assay,:contributor => User.current_user.person,
                            :study => (Factory(:study, :investigation => (Factory(:investigation)))))
    assay.data_file_masters << df
    assay.model_masters << model
    assert assay.save
    assert assay.is_modelling?

    get :show, :id => assay
    assert_response :success
    assert_select "a[href=?]", data_file_path(df), :text => df.title
    assert_select "a[href=?]", model_path(model), :text => model.title
  end

  test 'should have associated datafiles, models and sops on assay index page for modelling assays' do
      Assay.delete_all
      df = Factory(:data_file,:contributor => User.current_user)
      model = Factory(:model,:contributor => User.current_user)
      sop = Factory(:sop,:contributor => User.current_user)
      assay= Factory(:modelling_assay,:contributor => User.current_user.person,
                              :study => (Factory(:study, :investigation => (Factory(:investigation)))))
      assay.data_file_masters << df
      assay.model_masters << model
      assay.sop_masters << sop
      assert assay.save
      assert assay.is_modelling?

      get :index
      assert_response :success
      assert_select "a[href=?]", data_file_path(df), :text => df.title
      assert_select "a[href=?]", model_path(model), :text => model.title
      assert_select "a[href=?]", sop_path(sop), :text => sop.title
  end

  test 'should have only associated datafiles and sops on assay index page for experimental assays' do
        Assay.delete_all
        df = Factory(:data_file,:contributor => User.current_user)
        model = Factory(:model,:contributor => User.current_user)
        sop = Factory(:sop,:contributor => User.current_user)
        assay= Factory(:experimental_assay,:contributor => User.current_user.person,
                                :study => (Factory(:study, :investigation => (Factory(:investigation)))))
        assay.data_file_masters << df
        assay.model_masters << model
        assay.sop_masters << sop
        assert assay.save
        assert assay.is_experimental?

        get :index
        assert_response :success
        assert_select "a[href=?]", data_file_path(df), :text => df.title
        assert_select "a[href=?]", model_path(model), :text => model.title, :count => 0
        assert_select "a[href=?]", sop_path(sop), :text => sop.title
  end

  test "preview assay with associated hidden items" do
    assay = Factory(:assay,:policy=>Factory(:public_policy))
    private_df = Factory(:data_file,:policy=>Factory(:private_policy))
    assay.data_file_masters << private_df
    assay.save!
    login_as Factory(:user)
    xhr(:get, :preview,{:id=>assay.id})
    assert_response :success
  end

  test "should not show private data or model title on modelling analysis summary" do
    df = Factory(:data_file, :title=>"private data file", :policy=>Factory(:private_policy))
    df2 = Factory(:data_file, :title=>"public data file", :policy=>Factory(:public_policy))
    model = Factory(:model, :title=>"private model", :policy=>Factory(:private_policy))
    model2 = Factory(:model, :title=>"public model", :policy=>Factory(:public_policy))
    assay = Factory(:modelling_assay,:policy=>Factory(:public_policy))

    assay.data_file_masters << df
    assay.data_file_masters << df2
    assay.model_masters << model
    assay.model_masters << model2

    assay.save!

    login_as Factory(:person)

    get :show,:id=>assay.id
    assert_response :success
    assert_select "div.data_model_relationship" do
      assert_select "ul.related_models" do
        assert_select "li a[href=?]",model_path(model2),:text=>/#{model2.title}/,:count=>1
        assert_select "li a[href=?]",model_path(model),:text=>/#{model.title}/,:count=>0
        assert_select "li",:text=>/Hidden/,:count=>1
      end
      assert_select "ul.related_data_files" do
        assert_select "li a[href=?]",data_file_path(df2),:text=>/#{df2.title}/,:count=>1
        assert_select "li a[href=?]",data_file_path(df),:text=>/#{df.title}/,:count=>0
        assert_select "li",:text=>/Hidden/,:count=>1
      end
    end

  end



  test "should not show investigation and study title if they are hidden on assay show page" do
    investigation = Factory(:investigation,
                            :policy=>Factory(:private_policy),
                            :contributor => User.current_user)
    study = Factory(:study,
                    :policy=>Factory(:private_policy),
                    :contributor => User.current_user,
                    :investigation => investigation)
    assay = Factory(:assay,
                    :policy=>Factory(:public_policy),
                    :study => study)

    logout
    get :show, :id => assay
    assert_response :success
    assert_select "p#investigation" do
      assert_select "span.none_text", :text => /hidden item/, :count => 1
    end
    assert_select "p#study" do
      assert_select "span.none_text", :text => /hidden item/, :count => 1
    end
  end

  test "edit should include tags element" do
    assay = Factory(:assay,:policy=>Factory(:public_policy))
    get :edit, :id=>assay.id
    assert_response :success

    assert_select "div.foldTitle",:text=>/Tags/,:count=>1
    assert_select "div#tag_ids",:count=>1
  end

  test "new should include tags element" do
    get :new,:class=>:experimental
    assert_response :success
    assert_select "div.foldTitle",:text=>/Tags/,:count=>1
    assert_select "div#tag_ids",:count=>1
  end

  test "edit should include not include tags element when tags disabled" do
    with_config_value :tagging_enabled,false do
      assay = Factory(:assay,:policy=>Factory(:public_policy))
      get :edit, :id=>assay.id
      assert_response :success

      assert_select "div.foldTitle",:text=>/Tags/,:count=>0
      assert_select "div#tag_ids",:count=>0
    end
  end

  test "new should not include tags element when tags disabled" do
    with_config_value :tagging_enabled,false do
      get :new,:class=>:experimental
      assert_response :success
      assert_select "div.foldTitle",:text=>/Tags/,:count=>0
      assert_select "div#tag_ids",:count=>0
    end
  end

  test "new object based on existing one" do
    investigation = Factory(:investigation,:policy=>Factory(:public_policy))
    study = Factory(:study,:policy=>Factory(:public_policy), :investigation => investigation)
    assay = Factory(:assay,:policy=>Factory(:public_policy),:title=>"the assay",:study=>study)
    assert assay.can_view?
    assert assay.study.can_edit?
    get :new_object_based_on_existing_one,:id=>assay.id
    assert_response :success
    assert_select "textarea#assay_title",:text=>"the assay"
    assert_select "select#assay_study_id option[selected][value=?]",assay.study.id,:count=>1
  end

  test "new object based on existing one when unauthorised to view" do
    assay = Factory(:assay,:policy=>Factory(:private_policy),:title=>"the assay")
    refute assay.can_view?
    get :new_object_based_on_existing_one,:id=>assay.id
    assert_response :forbidden
  end

  test "new object based on existing one when can view but not logged in" do
    assay = Factory(:assay,:policy=>Factory(:public_policy))
    logout
    assert assay.can_view?
    get :new_object_based_on_existing_one, :id=>assay.id
    assert_redirected_to assay
    refute_nil flash[:error]
  end

  test "should show experimental assay types for new experimental assay" do
    get :new,:class=>:experimental
    assert_response :success
    assert_select "label",:text=>/assay type/i
    assert_select "select#assay_assay_type_uri" do
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:text=>/Fluxomics/i
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Cell_cycle",:text=>/Cell cycle/i,:count=>0
    end
  end

  test "should show modelling assay types for new modelling assay" do
    get :new,:class=>:modelling
    assert_response :success
    assert_select "label",:text=>/Biological problem addressed/i
    assert_select "select#assay_assay_type_uri" do
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Cell_cycle",:text=>/Cell cycle/i
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:text=>/Fluxomics/i,:count=>0
    end
  end

  test "should show experimental assay types when editing experimental assay" do
    a = Factory(:experimental_assay,:contributor=>User.current_user.person)
    get :edit,:id=>a.id
    assert_response :success
    assert_select "label",:text=>/assay type/i
    assert_select "select#assay_assay_type_uri" do
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:text=>/Fluxomics/i
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Cell_cycle",:text=>/Cell cycle/i,:count=>0
    end
  end

  test "should show modelling assay types when editing modelling assay" do
    a = Factory(:modelling_assay,:contributor=>User.current_user.person)
    get :edit,:id=>a.id
    assert_response :success
    assert_select "label",:text=>/Biological problem addressed/i
    assert_select "select#assay_assay_type_uri" do
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Cell_cycle",:text=>/Cell cycle/i
      assert_select "option[value=?]","http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:text=>/Fluxomics/i,:count=>0
    end
  end

  test "assays filtered by investigation via nested routing" do
    assert_routing "investigations/1/assays",{controller:"assays",action:"index",investigation_id:"1"}
    assay = Factory(:assay,:policy=>Factory(:public_policy))
    inv = assay.study.investigation
    assay2 = Factory(:assay,:policy=>Factory(:public_policy))
    refute_nil(inv)
    refute_equal assay.study.investigation, assay2.study.investigation
    get :index,investigation_id:inv.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",assay_path(assay),:text=>assay.title
      assert_select "p > a[href=?]",assay_path(assay2),:text=>assay2.title,:count=>0
    end
  end

  test "assays filtered by study via nested routing" do
    assert_routing "studies/1/assays",{controller:"assays",action:"index",study_id:"1"}
    assay = Factory(:assay,:policy=>Factory(:public_policy))
    study = assay.study
    assay2 = Factory(:assay,:policy=>Factory(:public_policy))

    refute_equal assay.study, assay2.study
    get :index,study_id:study.id
    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "p > a[href=?]",assay_path(assay),:text=>assay.title
      assert_select "p > a[href=?]",assay_path(assay2),:text=>assay2.title,:count=>0
    end
  end

  test "filtered assays for non existent study" do
    Factory :assay #needs an assay to be sure that the problem being fixed is triggered
    study_id=999
    assert_nil Study.find_by_id(study_id)
    get :index,:study_id=>study_id
    assert_response :not_found
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to assays_path
  end

  test "assays filtered by strain through nested route" do
    assert_routing "strains/3/assays",{controller:"assays",action:"index",strain_id:"3"}
    ao1 = Factory(:assay_organism,:assay=>Factory(:assay,:policy=>Factory(:public_policy)))
    ao2 = Factory(:assay_organism,:assay=>Factory(:assay,:policy=>Factory(:public_policy)))
    strain1 = ao1.strain
    strain2 = ao2.strain
    assay1=ao1.assay
    assay2=ao2.assay

    refute_nil strain1
    refute_nil strain2
    refute_equal strain1,strain2
    refute_nil assay1
    refute_nil assay2
    refute_equal assay1,assay2

    assert_include assay1.strains,strain1
    assert_include assay2.strains,strain2

    assert_include strain1.assays,assay1
    assert_include strain2.assays,assay2

    assert strain1.can_view?
    assert strain2.can_view?

    get :index,strain_id:strain1.id
    assert_response :success

    assert_select "div.list_item_title" do
      assert_select "a[href=?]",assay_path(assay1),:text=>assay1.title
      assert_select "a[href=?]",assay_path(assay2),:text=>assay2.title,:count=>0
    end

  end

  test 'faceted browsing config for Assay' do
    Factory(:assay, :policy => Factory(:public_policy))
    with_config_value :faceted_browsing_enabled,true do
      get :index
      assert_select "div[data-ex-facet-class='TextSearch']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.organism']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.assay_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.technology_type'][data-ex-facet-class='Exhibit.HierarchicalFacet']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.project']", :count => 1
      assert_select "div[data-ex-role='facet'][data-ex-expression='.for_test']", :count => 0
    end
  end

  test 'content config for Assay' do
    with_config_value :faceted_browsing_enabled,true do
      get :index
      assert_select "div[data-ex-role='exhibit-view'][data-ex-label='Tiles'][data-ex-paginate='true']", :count => 1
    end
  end

  test 'show only authorized items for faceted browsing' do
    with_config_value :faceted_browsing_enabled,true do
      assay1 = Factory(:assay, :policy => Factory(:public_policy))
      assay2 = Factory(:assay, :policy => Factory(:private_policy))
      assert assay1.can_view?
      assert !assay2.can_view?
      @request.env['HTTP_REFERER'] = '/assays/items_for_result'
      xhr :post, "items_for_result",{:items => "Assay_#{assay1.id},Assay_#{assay2.id}"}
      items_for_result =  ActiveSupport::JSON.decode(@response.body)['items_for_result']
      assert items_for_result.include?(assay1.title)
      assert !items_for_result.include?(assay2.title)
    end
  end
end
