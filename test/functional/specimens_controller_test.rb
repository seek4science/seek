require "test_helper"

class SpecimensControllerTest < ActionController::TestCase

  fixtures :all
  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include FunctionalAuthorizationTests

  def setup
    login_as :owner_of_fully_public_policy
  end

  def rest_api_test_object
    @object = Factory(:specimen, :contributor => User.current_user,
                      :title => "test1",
                      :policy => policies(:policy_for_viewable_data_file))
  end

  test "index xml validates with schema" do
    Factory(:specimen, :contributor => User.current_user,
            :title => "test2",
            :policy => policies(:policy_for_viewable_data_file))
    Factory :specimen, :policy => policies(:editing_for_all_sysmo_users_policy)
    get :index, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:specimens)

    validate_xml_against_schema(@response.body)

  end

  test "show xml validates with schema" do
    s =Factory(:specimen, :contributor => User.current_user,
               :title => "test2",
               :policy => policies(:policy_for_viewable_data_file))
    get :show, :id => s, :format =>"xml"
    assert_response :success
    assert_not_nil assigns(:specimen)

    validate_xml_against_schema(@response.body)
  end
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:specimens)
  end
  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:specimen)

  end
  test "should create" do
    assert_difference("Specimen.count") do
      post :create, :specimen => {:title => "running mouse NO.1",
                                  :organism_id=>Factory(:organism).id,
                                  :lab_internal_number =>"Do232",
                                  :institution_id => Factory(:institution).id,
                                  :strain_id => Factory(:strain).id,
                                  :project_ids => [Factory(:project).id]}

    end
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "running mouse NO.1", s.title
  end
  test "should get show" do
    get :show, :id => Factory(:specimen,
                              :title=>"running mouse NO2",
                              :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end

  test "should get edit" do
    get :edit, :id=> Factory(:specimen, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end
  test "should update" do
    specimen = Factory(:specimen, :title=>"Running mouse NO3", :policy =>policies(:editing_for_all_sysmo_users_policy))
    creator1= Factory(:person,:last_name =>"test1")
    creator2 = Factory(:person,:last_name =>"test2")
    assert_not_equal "test", specimen.title
    put :update, :id=>specimen.id, :specimen =>{:title =>"test",:project_ids => [Factory(:project).id]},
        :creators => [[creator1.name,creator1.id],[creator2.name,creator2.id]].to_json
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "test", s.title
  end

  test "should destroy" do
    s = Factory :specimen, :contributor => User.current_user
    assert_difference("Specimen.count", -1, "A specimen should be deleted") do
      delete :destroy, :id => s.id
    end
  end
  test "unauthorized users cannot add new specimens" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    get :new
    assert_response :redirect
  end
  test "unauthorized user cannot edit specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)
    get :edit, :id =>s.id
    assert_redirected_to specimen_path(s)
    assert flash[:error]
  end
  test "unauthorized user cannot update specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)

    put :update, :id=> s.id, :specimen =>{:title =>"test"}
    assert_redirected_to specimen_path(s)
    assert flash[:error]
  end

  test "unauthorized user cannot delete specimen" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :specimen, :policy => Factory(:private_policy)
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to s
  end

  test "only current user can delete specimen" do

    s = Factory :specimen, :contributor => User.current_user
    assert_difference("Specimen.count", -1, "A specimen should be deleted") do
      delete :destroy, :id => s.id
    end

    s = Factory :specimen
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to s
  end
  test "should not destroy specimen related to an existing sample" do
    sample = Factory :sample
    specimen = Factory :specimen
    specimen.samples = [sample]
    assert_no_difference("Specimen.count") do
      delete :destroy, :id => specimen.id
    end
    assert flash[:error]
    assert_redirected_to specimen
  end

  test "should create specimen with strings for confluency passage viability and purity" do
    attrs = [:confluency, :passage, :viability, :purity]
    specimen= Factory.attributes_for :specimen,
                                     :confluency => "Test", :passage => "Test",
                                     :viability => "Test", :purity => "Test",
                                     :project_ids => [Factory(:project).id]

    specimen[:strain_id]=Factory(:strain).id
    post :create, :specimen => specimen
    assert specimen = assigns(:specimen)

    assert_redirected_to specimen

    attrs.each do |attr|
      assert_equal "Test", specimen.send(attr)
    end
  end

  test "should show without institution" do
    get :show, :id => Factory(:specimen,
                              :title=>"running mouse NO2 with no institution",
                              :policy =>policies(:editing_for_all_sysmo_users_policy),
                              :institution_id=>nil)
    assert_response :success
    assert_not_nil assigns(:specimen)
  end

test "should update genotypes and phenotypes" do
         specimen = Factory(:specimen)
         genotype1 = Factory(:genotype, :specimen => specimen)
         genotype2 = Factory(:genotype, :specimen => specimen)

         phenotype1 = Factory(:phenotype, :specimen => specimen)
         phenotype2 = Factory(:phenotype, :specimen => specimen)

         new_gene_title = 'new gene'
         new_modification_title = 'new modification'
         new_phenotype_description = "new phenotype"
         login_as(specimen.contributor)
         #[genotype1,genotype2] =>[genotype2,new genotype]
         put :update,:id=>specimen.id,
                                    :specimen => {
                                    :genotypes_attributes => {'0' => {:gene_attributes => {:title => genotype2.gene.title, :id => genotype2.gene.id }, :id=>genotype2.id, :modification_attributes => {:title => genotype2.modification.title,:id=>genotype2.modification.id }},
                                                              "2"=>{:gene_attributes => {:title => new_gene_title},:modification_attributes => {:title => new_modification_title }},
                                                              "1"=>{:id => genotype1.id, :_destroy => 1}},
                                    :phenotypes_attributes => { '0'=>{:description=>phenotype2.description,:id=>phenotype2.id},'2343243'=>{:id=>phenotype1.id,:_destroy=>1},"1"=>{:description=>new_phenotype_description} }
                                    }
         assert_redirected_to specimen_path(specimen)

         updated_specimen = Specimen.find_by_id specimen.id
         new_gene = Gene.find_by_title(new_gene_title)
         new_modification = Modification.find_by_title(new_modification_title)
         new_genotype = Genotype.find(:all, :conditions => ["gene_id=? and modification_id=?", new_gene.id, new_modification.id]).first
         new_phenotype = Phenotype.find_all_by_description(new_phenotype_description).sort_by(&:created_at).last
         updated_genotypes = [genotype2, new_genotype].sort_by(&:id)
         assert_equal updated_genotypes, updated_specimen.genotypes.sort_by(&:id)

         updated_phenotypes = [phenotype2, new_phenotype].sort_by(&:id)
         assert_equal updated_phenotypes, updated_specimen.phenotypes.sort_by(&:id)
   end

  test "specimen-sop association when sop has multiple versions" do
    sop = Factory :sop, :contributor => User.current_user
    sop_version_2 = Factory(:sop_version, :sop => sop)
    assert_equal 2, sop.versions.count
    assert_equal sop.latest_version, sop_version_2

    assert_difference("Specimen.count") do
      post :create, :specimen => {:title => "running mouse NO.1",
                                  :organism_id => Factory(:organism).id,
                                  :lab_internal_number => "Do232",
                                  :institution_id => Factory(:institution).id,
                                  :strain_id => Factory(:strain).id,
                                  :project_ids => [Factory(:project).id]},
                    :specimen_sop_ids => [sop.id]

    end
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_nil flash[:error]
    assert_equal "running mouse NO.1", s.title
    assert_equal 1, s.sop_masters.length
    assert_equal sop, s.sop_masters.map(&:sop).first
    assert_equal 1, s.sops.length
    assert_equal sop_version_2, s.sops.first
  end

  test 'should associate sops' do
    sop = Factory(:sop, :policy => Factory(:public_policy))
    specimen= Factory.attributes_for :specimen,
                                     :confluency => "Test", :passage => "Test",
                                     :viability => "Test", :purity => "Test",
                                     :project_ids => [Factory(:project).id]
    specimen[:strain_id]=Factory(:strain).id

    post :create, :specimen => specimen, :specimen_sop_ids => [sop.id]
    assert specimen = assigns(:specimen)

    assert_redirected_to specimen
    associated_sops = specimen.sop_masters.collect(&:sop)
    assert_equal 1, associated_sops.size
    assert_equal sop, associated_sops.first
  end

  test 'should unassociate sops' do
    sop = Factory(:sop, :policy => Factory(:public_policy))
    specimen = Factory(:specimen)
    login_as specimen.contributor
    sop_master = SopSpecimen.create!(:sop_id => sop.id, :sop_version => 1, :specimen_id => specimen.id)
    specimen.sop_masters << sop_master
    associated_sops = specimen.sop_masters.collect(&:sop)
    specimen.reload
    assert_equal 1, associated_sops.size
    assert_equal sop, associated_sops.first

    put :update, :id => specimen.id, :specimen_sop_ids => []
    specimen.reload
    associated_sops = specimen.sop_masters.collect(&:sop)
    assert associated_sops.empty?
    #sop_master can not be deleted because no specified version
    assert_not_nil SopSpecimen.find_by_id(sop_master.id)
  end

  test 'should not unassociate private sops' do
    sop = Factory(:sop, :policy => Factory(:public_policy))
    specimen = Factory(:specimen)
    login_as specimen.contributor
    specimen.sop_masters << SopSpecimen.create!(:sop_id => sop.id, :sop_version => 1, :specimen_id => specimen.id)
    associated_sops = specimen.sop_masters.collect(&:sop)
    specimen.reload
    assert_equal 1, associated_sops.size
    assert_equal sop, associated_sops.first

    disable_authorization_checks do
      sop.policy = Factory(:private_policy)
      sop.save
    end

    put :update, :id => specimen.id, :specimen_sop_ids => []
    specimen.reload
    assert_equal 1, associated_sops.size
    assert_equal sop, associated_sops.first
  end
end
