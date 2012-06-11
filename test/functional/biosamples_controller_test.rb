require 'test_helper'

class BioSamplesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
    @controller = BiosamplesController.new()
  end

  test 'should get the biosamples index page' do
    get :index
    assert_response :success
  end

  test 'should get the create_strain_popup' do
    get :create_strain_popup
    assert_response :success
    end

  test 'should get strain form' do
    get :strain_form
    assert_response :success
  end

  test 'should not be able to go to the create_strain_popup without login' do
    @request.env["HTTP_REFERER"]  = ''
    logout
    get :create_strain_popup
    assert_not_nil flash[:error]
  end

  test 'should show existing strains for selected organisms' do
    organism1 = organisms(:yeast)
    strains_of_organism1 = organism1.strains.reject { |s| s.is_dummy? }
    organism2 = organisms(:Saccharomyces_cerevisiae)
    strains_of_organism2 = organism2.strains.reject { |s| s.is_dummy? }
    #organism3 doesn't have any strains
    organism3 = organisms(:human)
    strains_of_organism3 = organism3.strains.reject { |s| s.is_dummy? }

    strains = strains_of_organism1 + strains_of_organism2 + strains_of_organism3

    organism_ids = organism1.id.to_s + ',' + organism2.id.to_s  + ',' + organism3.to_s
    get :existing_strains, :organism_ids => organism_ids
    assert_response :success
    assert_select "table#strain_table tbody" do
      assert_select 'tr td a[href=?]', organism_path(organism1.id), :count => strains_of_organism1.length
      assert_select 'tr td a[href=?]', organism_path(organism2.id), :count => strains_of_organism2.length
      assert_select 'tr td a[href=?]', organism_path(organism3.id), :count => strains_of_organism3.length
      strains.each do |strain|
        assert_select 'tr td', :text => strain.id, :count => 1
      end
    end
  end

  test "should show existing specimens for selected strains" do
    strain1 = strains(:yeast1)
    specimens_of_strain1 = strain1.specimens.select(&:can_view?)
    strain2 = strains(:yeast2)
    specimens_of_strain2 = strain2.specimens.select(&:can_view?)
    #strain3 doesn't have any specimens
    strain3 = strains(:Saccharomyces_cerevisiae1)
    specimens_of_strain3 = strain3.specimens.select(&:can_view?)
    specimens = specimens_of_strain1 + specimens_of_strain2 + specimens_of_strain3

    strain_ids = strain1.id.to_s + ',' + strain2.id.to_s + ',' + strain3.id.to_s
    get :existing_specimens, :strain_ids => strain_ids
    assert_response :success
    assert_select "table#specimen_table tbody" do
      assert_select 'tr td', :text => "Strain " + strain1.info + "(Seek ID=#{strain1.id})", :count => specimens_of_strain1.length
      assert_select 'tr td', :text => "Strain " + strain2.info + "(Seek ID=#{strain2.id})", :count => specimens_of_strain2.length
      assert_select 'tr td', :text => "Strain " + strain3.info + "(Seek ID=#{strain3.id})", :count => specimens_of_strain3.length
      specimens.each do |specimen|
        assert_select 'tr td', :text => specimen.id, :count => 1
      end
    end
  end

  test "should show existing samples for selected specimens" do
    specimen1 = specimens("running mouse")
    samples_of_specimen1 = specimen1.samples.select(&:can_view?)
    specimen2 = specimens("running mouse2")
    samples_of_specimen2 = specimen2.samples.select(&:can_view?)

    samples = samples_of_specimen1 + samples_of_specimen2

    specimen_ids = specimen1.id.to_s + ',' + specimen2.id.to_s
    get :existing_samples, :specimen_ids => specimen_ids
    assert_response :success
    assert_select "table#sample_table tbody" do
      assert_select 'tr td', :text => CELL_CULTURE_OR_SPECIMEN.capitalize + ' ' + specimen1.title, :count => samples_of_specimen1.length
      assert_select 'tr td', :text => CELL_CULTURE_OR_SPECIMEN.capitalize + ' ' + specimen2.title, :count => samples_of_specimen2.length
      samples.each do |sample|
        assert_select 'tr td', :text => sample.id, :count => 1
      end
    end
  end


  test 'should create strain with name and organism' do
    organism = organisms(:yeast)
    strain = {:title => 'test', :organism => organism}
    assert_difference ('Strain.count') do
      post :create_strain, :strain => strain
    end
    assert_response :success
  end

  test 'should not be able to create strain without login' do
    logout
    organism = organisms(:yeast)
    strain = {:title => 'test', :organism => organism}
    assert_no_difference ('Strain.count') do
      post :create_strain, :strain => strain
    end
  end


  test "should update the strain list in specimen_form" do
    organism = organisms(:yeast)
    strains = organism.strains
    assert_equal 2, strains.select{|s| !s.is_dummy?}.count
    new_strain = Factory(:strain, :organism => organism)
    organism.reload
    strains =  organism.strains
    assert_equal 3, strains.select{|s| !s.is_dummy?}.count

    xml_http_request(:get, :strains_of_selected_organism, {:organism_id => organism.id})

    received_data = ActiveSupport::JSON.decode(@response.body)
    assert 200, received_data['status']
    received_strains = received_data["strains"]
    assert_equal 3, received_strains.count
    assert received_strains.include?([new_strain.id, new_strain.info])
  end

  test "should have age at sampling in sample table" do
    specimen = specimens("running mouse")
    xhr(:get, :existing_samples, {:specimen_ids => "#{specimen.id}"})
    assert_response :success
    assert_select "table#sample_table thead tr th", :text => "Age at sampling(hours)", :count => 1
  end

  test "should have comment in sample table" do
    specimen = specimens("running mouse")
    xhr(:get, :existing_samples, {:specimen_ids => "#{specimen.id}"})
    assert_response :success
    assert_select "table#sample_table thead tr th", :text => "Comment", :count => 1
  end

  test "should have based on strain in strain table" do
    organism = organisms(:yeast)
    get :existing_strains, :organism_ids => organism.id.to_s
    assert_response :success
    assert_select "table#strain_table thead tr th", :text => "Based on", :count => 1
  end

  test "should be able to view only can_view strain" do
    organism = organisms(:yeast)
    private_strain = Factory(:strain, :organism => organism, :policy => Factory(:private_policy))
    assert organism.strains.include?private_strain
    get :existing_strains, :organism_ids => organism.id.to_s
    assert_response :success
    assert_select "table#strain_table tbody tr td", :text => private_strain.title, :count => 0
    assert_select "table#strain_table tbody tr td", :text => 'default', :count => 0
    assert_select "table#strain_table tbody tr td", :text => 'TRS99', :count => 1
    assert_select "table#strain_table tbody tr td", :text => 'ZX81', :count => 1
  end

  test 'should not allow to create specimen_sample which associates with the un-viewable strain' do
    assert_no_difference("Sample.count") do
      assert_no_difference("Specimen.count") do
        post :create_specimen_sample, :sample => {:title => "test",
                                                  :projects => [Factory(:project)],
                                                  :lab_internal_number => "Do232"},
             :specimen => {:title => 'test',
                           :lab_internal_number => 'lab123',
                           :strain => Factory(:strain, :policy => Factory(:private_policy))
             }
      end
    end
  end

  test 'should not allow to create sample which associates with the un-viewable specimen' do
      assert_no_difference("Sample.count") do
        post :create_specimen_sample, :sample => {:title => "test",
                                                  :projects => [Factory(:project)],
                                                  :lab_internal_number => "Do232"},
             :specimen => Factory(:specimen, :policy => Factory(:private_policy))

      end
  end

  test "should update strain" do
    strain = Factory(:strain)
    login_as(strain.contributor)
    new_project = Factory(:project)
    new_title = 'new title'
    put :update_strain, :strain => {:id => strain.id, :project_ids =>[new_project.id.to_s], :title => new_title}, :sharing =>{:sharing_scope => Policy::PRIVATE, :access_type_0 => Policy::NO_ACCESS}
    assert_response :success
    updated_strain = Strain.find_by_id strain.id
    assert_equal new_title, updated_strain.title
    assert_equal [new_project], updated_strain.projects
    assert_equal Policy::PRIVATE, updated_strain.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, updated_strain.policy.access_type
  end

  test "should update strain phenotypes" do
      strain = Factory(:strain)
      phenotype1 = Factory(:phenotype, :strain => strain)
      phenotype2 = Factory(:phenotype, :strain => strain)

      new_phenotype_description = 'new phenotype'
      login_as(strain.contributor)
      put :update_strain, :strain => {:id => strain.id}, :phenotypes => {'0' => {:description => phenotype1.description}, '1' => {:description => new_phenotype_description}}
      assert_response :success

      updated_strain = Strain.find_by_id strain.id
      new_phenotype = Phenotype.find_by_description(new_phenotype_description)
      updated_phenotypes = [phenotype1, new_phenotype].sort_by(&:description)
      assert_equal updated_phenotypes, updated_strain.phenotypes.sort_by(&:description)
  end

  test "should update strain genotypes" do
        strain = Factory(:strain)
        genotype1 = Factory(:genotype, :strain => strain)
        genotype2 = Factory(:genotype, :strain => strain)

        new_gene_title = 'new gene'
        new_modification_title = 'new modification'
        login_as(strain.contributor)
        put :update_strain, :strain => {:id => strain.id}, :genotypes => {'0' => {:gene => {:title => new_gene_title }, :modification => {:title => new_modification_title }}, '1' => {:gene => {:title => genotype2.gene.title}, :modification => {:title => genotype2.modification.title}} }
        assert_response :success

        updated_strain = Strain.find_by_id strain.id
        new_gene = Gene.find_by_title(new_gene_title)
        new_modification = Modification.find_by_title(new_modification_title)
        new_genotype = Genotype.find(:all, :conditions => ["gene_id=? and modification_id=?", new_gene.id, new_modification.id]).first
        updated_genotypes = [genotype2, new_genotype].sort_by(&:id)
        assert_equal updated_genotypes, updated_strain.genotypes.sort_by(&:id)
  end

  test "should not be able to update the policy of the strain when having no manage rights" do
    strain = Factory(:strain, :policy => Factory(:policy, :sharing_scope => Policy::ALL_SYSMO_USERS, :access_type => Policy::EDITING))
    user = Factory(:user)
    assert strain.can_edit?user
    assert !strain.can_manage?(user)

    login_as(user)
      put :update_strain, :strain => {:id => strain.id}, :sharing =>{:sharing_scope => Policy::EVERYONE, :access_type_4 => Policy::EDITING }
    assert_response :success

    updated_strain = Strain.find_by_id strain.id
    assert_equal Policy::ALL_SYSMO_USERS, updated_strain.policy.sharing_scope
  end

  test "should not be able to update the permissions of the strain when having no manage rights" do
      strain = Factory(:strain, :policy => Factory(:policy, :sharing_scope => Policy::ALL_SYSMO_USERS, :access_type => Policy::EDITING))
      user = Factory(:user)
      assert strain.can_edit?user
      assert !strain.can_manage?(user)

      login_as(user)
        put :update_strain, :strain => {:id => strain.id}, :sharing=>{:permissions =>{:contributor_types => ActiveSupport::JSON.encode(['Person']), :values => ActiveSupport::JSON.encode({"Person" => {user.person.id =>  {"access_type" =>  Policy::MANAGING}}})}}
      assert_response :success

      updated_strain = Strain.find_by_id strain.id
      assert updated_strain.policy.permissions.empty?
      assert !updated_strain.can_manage?(user)
  end
end
