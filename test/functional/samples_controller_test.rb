require "test_helper"

class SamplesControllerTest < ActionController::TestCase
  fixtures :policies
  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases

  # Called before every test method runs. Can be used
  # to set up fixture information.

  def setup
    login_as Factory(:user,:person => Factory(:person,:roles_mask=> 0))
  end

  def rest_api_test_object
    @object = Factory(:sample,:contributor => User.current_user,
                      :title=> "test1",
                      :policy => policies(:policy_for_viewable_data_file))
  end

  test "index xml validates with schema" do
    Factory(:sample,
            :title=> "test2",
            :policy => policies(:policy_for_viewable_data_file))
    Factory :sample, :policy => policies(:editing_for_all_sysmo_users_policy)
    get :index, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:samples)
    validate_xml_against_schema(@response.body)
  end

  test "show xml validates with schema" do
    s = Factory(:sample,:contributor => Factory(:user,:person => Factory(:person,:roles_mask=> Person::ROLES_MASK_FOR_ADMIN)),
                :title => "test sample",
                :policy => policies(:policy_for_viewable_data_file))
    get :show, :id => s, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:sample)
    validate_xml_against_schema(@response.body)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:samples)
  end

  test "related specimen tab title" do
    s = Factory :sample,:policy=>Factory(:public_policy),:specimen=>Factory(:specimen,:policy=>Factory(:public_policy))
    assert !s.specimen.nil?
    assert s.specimen.can_view?

    get :show, :id=>s
    assert_response :success

    assert_select "div#specimens" do
      assert_select "h3", :text=>/#{I18n.t('biosamples.sample_parent_term').pluralize}/
    end
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:sample)
  end

  test "should create" do
    specimen = Factory(:specimen, :contributor => User.current_user)
    assert_difference("Sample.count") do
      post :create, :sample => {:title => "test",
                                :project_ids=>[Factory(:project).id],
                                :lab_internal_number =>"Do232",
                                :donation_date => Date.today,
                                :specimen_id => specimen.id }
    end
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_equal "test", s.title
    assert_equal specimen,s.specimen
  end

  test "should create sample and specimen" do
    creator=Factory :person
    proj1=Factory(:project)
    proj2=Factory(:project)
    sop = Factory :sop,:contributor=>User.current_user
    assert_difference("Sample.count") do
      assert_difference("Specimen.count") do
        post :create,
            :specimen_sop_ids=>[sop.id],
            :organism_id=>Factory(:organism).id,
            :creators=>[[creator.name,creator.id]].to_json,
            :specimen=>{:other_creators=>"jesus jones"},
            :sample => {
            :title => "test",
            :project_ids=>[proj1.id,proj2.id],
            :lab_internal_number =>"Do232",
            :donation_date => Date.today,
            :specimen_attributes => {:strain_id => Factory(:strain).id,
                          :lab_internal_number=>"Lab number",
                          :title=>"Donor number",
                          :institution_id =>Factory(:institution).id
            }
        }
      end
    end
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_equal "test",s.title
    assert_not_nil s.specimen
    assert_equal "Donor number",s.specimen.title
    assert_equal [sop],s.specimen.sops.collect{|sop| sop.parent}
    assert s.specimen.creators.include?(creator)
    assert_equal 1,s.specimen.creators.count
    assert_equal "jesus jones",s.specimen.other_creators
    assert_equal 2,s.projects.count
    assert s.projects.include?(proj1)
    assert s.projects.include?(proj2)
    assert_equal s.projects,s.specimen.projects
  end

  test "should create sample and specimen with default strain if missing" do
    with_config_value :is_virtualliver,true do
      assert_difference("Sample.count") do
        assert_difference("Specimen.count") do
          assert_difference("Strain.count") do
            post :create,
                 :organism=>Factory(:organism),
                 :sample => {
                     :title => "test",
                     :project_ids=>[Factory(:project).id],
                     :lab_internal_number =>"Do232",
                     :donation_date => Date.today,
                     :specimen_attributes => {
                         :lab_internal_number=>"Lab number",
                       :institution_id =>Factory(:institution).id,
                         :title=>"Donor number"
                     }
                 }
          end
        end
      end
      s = assigns(:sample)
      assert_redirected_to sample_path(s)
      assert s.specimen.strain.is_dummy?
      assert_equal "test",s.title
      assert_not_nil s.specimen
      assert_equal "Donor number",s.specimen.title
    end
  end

  test "should create sample specimen with genotypes and phenotypes" do
    new_gene_title = 'new gene'
    new_modification_title = 'new modification'
    new_phenotype_description = "new phenotype"
    assert_difference(["Sample.count","Specimen.count"]) do
          post :create,
               :organism_id => Factory(:organism).id,
               :sample => {
                   :title => "test",
                   :project_ids => [Factory(:project).id],
                   :lab_internal_number => "Do232",
                   :donation_date => Date.today,
                   :specimen_attributes => {
                       :strain_id => Factory(:strain).id,
                       :lab_internal_number => "Lab number",
                       :institution_id =>Factory(:institution).id,
                       :title => "Donor number",
                       :genotypes_attributes => {"1234432"=>{:gene_attributes => {:title => new_gene_title},
                                                               :modification_attributes => {:title => new_modification_title}}},
                        :phenotypes_attributes => {"213213"=>{:description => new_phenotype_description}}
                       }

                   }

    end
    s = assigns(:sample)

    assert_redirected_to sample_path(s)
    assert_equal "test", s.title
    assert_not_nil s.specimen
    assert_equal "Donor number", s.specimen.title
    assert_equal "new modification new gene", s.specimen.genotype_info
    assert_equal "new phenotype", s.specimen.phenotype_info

  end



  test "should get show" do
    get :show, :id => Factory(:sample, :title=>"test", :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:sample)
  end

  test "should get edit" do
    get :edit, :id=> Factory(:sample, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:sample)
  end

  test "should update" do
    s = Factory(:sample, :title=>"oneSample", :policy =>policies(:editing_for_all_sysmo_users_policy))
    new_specimen = Factory(:specimen, :policy => Factory(:public_policy))
    assert_not_equal "test", s.title
    put :update, :id=>s, :sample =>{:title =>"test", :specimen_id => new_specimen.id}
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_equal "test", s.title
    assert_equal new_specimen, s.specimen
  end

  test "should destroy" do
    s = Factory :sample, :contributor => User.current_user
    assert_difference("Sample.count", -1, "A sample should be deleted") do
      delete :destroy, :id => s.id
    end
  end

  test "unauthorized users cannot add new samples" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    get :new
    assert_response :redirect
  end

  test "unauthorized user cannot edit sample" do
    s = Factory :sample, :policy => Factory(:private_policy), :contributor => Factory(:user)
    get :edit, :id =>s.id
    assert_redirected_to sample_path(s)
    assert flash[:error]
  end

  test "unauthorized user cannot update sample" do
    s = Factory :sample, :policy => Factory(:private_policy), :contributor => Factory(:user)

    put :update, :id=> s.id, :sample =>{:title =>"test"}
    assert_redirected_to sample_path(s)
    assert flash[:error]
  end

  test "unauthorized user cannot delete sample" do
    s = Factory :sample, :policy => Factory(:private_policy), :contributor => Factory(:user)
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test "only current user can delete sample" do
    s = Factory :sample, :contributor => User.current_user
    assert_difference("Sample.count", -1, "A sample should be deleted") do
      delete :destroy, :id => s.id
    end
    s = Factory :sample, :contributor => Factory(:user)
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test "should not destroy sample related to an existing assay" do
    s = Factory :sample, :assays => [Factory(:experimental_assay)], :contributor => Factory(:user)
    assert_no_difference("Sample.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test "should not show organism and strain information of a sample if there is no organism" do
    s = Factory :sample, :contributor => User.current_user
    s.specimen.strain.organism = nil
    s.save
    s.reload
    get :show, :id => s.id
    assert_response :success
    assert_not_nil assigns(:sample)
    assert_select 'p', :text => s.specimen.strain.info, :count => 0
  end
  
  test "associate data files and sops" do
      assert_difference("Sample.count") do
      post :create, :sample => {:title=>"test",
                                :lab_internal_number =>"Do232",
                                :donation_date => Date.today,
                                 :project_ids =>[Factory(:project).id],
                                :specimen_id => Factory(:specimen, :contributor => User.current_user).id},
             :sample_data_file_ids => [Factory(:data_file,:title=>"testDF",:contributor=>User.current_user).id],
             :sample_sop_ids => [Factory(:sop,:title=>"testSop",:contributor=>User.current_user).id]

    end
    s = assigns(:sample)
    assert_equal "testDF", s.data_files.first.title
    assert_equal "testSop", s.sops.first.title
  end


test "should show organism and strain information of a sample if there is organism" do
    specimen = Factory(:specimen, :contributor => User.current_user)
    sample = Factory :sample, :specimen_id => specimen.id, :contributor => User.current_user
    assert_equal true, sample.specimen.can_view?

    get :show, :id => sample.id
    assert_response :success
    assert_not_nil assigns(:sample)
    assert_select 'p a[href=?]', organism_path(sample.specimen.strain.organism), :count => 2 # one in the related cell cuture
  end

  test 'should have specimen comment and sex fields in the specimen/sample show page' do
    specimen = Factory(:specimen, :contributor => User.current_user)
    sample = Factory :sample, :specimen_id => specimen.id, :contributor => User.current_user
    assert_equal true, sample.specimen.can_view?

    get :show, :id => sample.id
    assert_response :success
    assert_select "label", :text => /Comment/, :count => 2 #one for specimen, one for sample
    assert_select "label", :text => /Gender/, :count => 1
  end

  test 'should have sample organism_part in the specimen/sample show page' do
    s = Factory :sample, :contributor => User.current_user
    get :show, :id => s.id
    assert_response :success
    assert_select "label", :text => /Organism part/, :count => 1
  end

  test 'should have sample organism_part in the sample edit page' do
    s = Factory :sample, :contributor => User.current_user
    get :edit, :id => s.id
    assert_response :success
    assert_select "select#sample_organism_part", :count => 1
  end

  test 'should have sample Comment in the specimen/sample show page' do
      specimen = Factory(:specimen, :contributor => User.current_user)
      sample = Factory :sample, :specimen_id => specimen.id, :contributor => User.current_user
      assert_equal true, sample.specimen.can_view?

      get :show, :id => sample.id
      assert_response :success
      assert_select "label", :text => /Comment/, :count => 2 #one for specimen, one for sample
  end

  test 'should have sample comment in the sample edit page' do
    s = Factory :sample, :contributor => User.current_user
    get :edit, :id => s.id
    assert_response :success
    assert_select "input#sample_comments", :count => 1
  end

  test "should not have 'New sample based on this one' for sysmo" do
    s = Factory :sample, :contributor => User.current_user
    get :show, :id => s.id
    assert_response :success
    assert_select "a", :text => /New sample based on this one/, :count => 0

    post :new_object_based_on_existing_one, :id => s.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'combined sample_specimen form when creating new sample' do
    get :new
    assert_response :success
    assert_select 'input#sample_specimen_attributes_title', :count => 1
  end

  test 'only sample form when updating sample' do
    get :edit, :id => Factory(:sample, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_select 'input#sample_specimen_attributes_title', :count => 0
  end

  test 'should have age at sampling' do
    get :new
    assert_response :success
    assert_select 'input#sample_age_at_sampling', :count => 1

    sample = Factory(:sample, :age_at_sampling => 4, :age_at_sampling_unit => Factory(:unit, :symbol => 's'))
    get :show, :id => sample.id
    assert_response :success
    assert_select "label", :text => /Age at sampling/

    get :edit, :id => sample.id
    assert_response :success
    assert_select "input#sample_age_at_sampling"
  end
  
  test "sample-sop association when sop has multiple versions" do
    sop = Factory :sop, :contributor => User.current_user
    sop_version_2 = Factory(:sop_version, :sop => sop)
    assert_equal 2, sop.versions.count
    assert_equal sop.latest_version, sop_version_2

    assert_difference("Sample.count") do
      post :create, :sample => {:title => "test",
                                :lab_internal_number => "Do232",
                                :donation_date => Date.today,
                                :project_ids => [Factory(:project).id],
                                :specimen_id => Factory(:specimen, :contributor => User.current_user).id},
           :sample_sop_ids => [sop.id]


    end
    s = assigns(:sample)
    assert_redirected_to sample_path(s)
    assert_nil flash[:error]
    assert_equal "test", s.title
    assert_equal 1, s.sop_masters.length
    assert_equal sop, s.sop_masters.first
    assert_equal 1, s.sops.length
    assert_equal sop_version_2, s.sops.first
  end
end
