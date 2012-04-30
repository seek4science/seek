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

  test 'should get the create sample popup' do
    get :create_sample_popup
    assert_response :success
  end

  test 'should get strain form' do
    get :new_strain_form
    assert_response :success
  end

  test 'should not be able to go to the create_strain_popup without login' do
    @request.env["HTTP_REFERER"]  = ''
    logout
    get :create_strain_popup
    assert_not_nil flash[:error]
  end

  test 'should not be able to go to the create_sample_popup without login' do
    @request.env["HTTP_REFERER"]  = ''
    logout
    get :create_sample_popup
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
      assert_select 'tr td', :text => "Strain " + strain1.info + "(ID=#{strain1.id})", :count => specimens_of_strain1.length
      assert_select 'tr td', :text => "Strain " + strain2.info + "(ID=#{strain2.id})", :count => specimens_of_strain2.length
      assert_select 'tr td', :text => "Strain " + strain3.info + "(ID=#{strain3.id})", :count => specimens_of_strain3.length
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

  test 'should create sample based on selected specimen' do
    specimen = Factory(:specimen, :contributor => User.current_user)
    assert_difference("Sample.count") do
      post :create_specimen_sample, :sample => {:title => "test",
                                :projects=>[Factory(:project)],
                                :lab_internal_number =>"Do232"},
           :specimen => {:id => specimen.id}
    end
  end

  test 'should create sample and specimen' do
    assert_difference("Sample.count") do
      assert_difference("Specimen.count") do
        post :create_specimen_sample, :sample => {:title => "test",
                                  :projects=>[Factory(:project)],
                                  :lab_internal_number =>"Do232"},
                          :specimen => {:title => 'test',
                                  :lab_internal_number => 'lab123',
                                  :strain => Factory(:strain)
                                  }
      end
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

  test 'should have comment and sex fields in the specimen_form' do
    xhr(:get, :create_sample_popup)
    assert_response :success
    assert_select "textarea#specimen_comments", :count => 1
    assert_select "select#specimen_sex", :count => 1
  end

  test 'should have organism_part in the sample_form' do
    xhr(:get, :create_sample_popup)
    assert_response :success
    assert_select "select#sample_organism_part", :count => 1
  end

  test "should have age at sampling in sample table" do
    specimen = specimens("running mouse")
    xhr(:get, :existing_samples, {:specimen_ids => "#{specimen.id}"})
    assert_response :success
    assert_select "table#sample_table thead tr th", :text => "Age at sampling(hours)", :count => 1
  end

  test 'should have comment in the sample_form' do
    xhr(:get, :create_sample_popup)
    assert_response :success
    assert_select "textarea#sample_comments", :count => 1
  end

  test "should have comment in sample table" do
    specimen = specimens("running mouse")
    xhr(:get, :existing_samples, {:specimen_ids => "#{specimen.id}"})
    assert_response :success
    assert_select "table#sample_table thead tr th", :text => "Comment", :count => 1
  end

  test "should have parent strain in strain table" do
    organism = organisms(:yeast)
    get :existing_strains, :organism_ids => organism.id.to_s
    assert_response :success
    assert_select "table#strain_table thead tr th", :text => "Parent", :count => 1
  end
end
