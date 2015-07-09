require 'test_helper'

class BioSamplesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    login_as(:aaron)
    @controller = BiosamplesController.new()
  end

  test 'should get the biosamples index page' do
    get :index
    assert_response :success
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
      assert_select 'tr td', :text => "Strain: " + strain1.info + "(Seek ID=#{strain1.id})", :count => specimens_of_strain1.length
      assert_select 'tr td', :text => "Strain: " + strain2.info + "(Seek ID=#{strain2.id})", :count => specimens_of_strain2.length
      assert_select 'tr td', :text => "Strain: " + strain3.info + "(Seek ID=#{strain3.id})", :count => specimens_of_strain3.length
      specimens.each do |specimen|
        assert_select 'tr td', :text => specimen.id, :count => 1
      end
    end
  end

  test "should have sop links in specimen table" do
    strain = strains(:yeast1)
    sop = Factory(:sop, :contributor => User.current_user)

    specimen = Factory(:specimen, :strain => strain, :contributor => User.current_user)
    login_as specimen.contributor
    specimen.sops = [sop]
    assert specimen.save
    specimen.reload

    assert specimen.can_view?
    assert sop.can_view?

    strain_ids = strain.id.to_s
    get :existing_specimens, :strain_ids => strain_ids
    assert_response :success

    assert_select "table#specimen_table tbody" do
      assert_select 'tr td a[href=?]', sop_path(sop), :count => 1
      assert_select 'tr td', :text => specimen.id, :count => 1
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
      assert_select 'tr td', :text => (I18n.t 'biosamples.sample_parent_term').capitalize + ': ' + specimen1.title, :count => samples_of_specimen1.length
      assert_select 'tr td', :text => (I18n.t 'biosamples.sample_parent_term').capitalize + ': ' + specimen2.title, :count => samples_of_specimen2.length
      samples.each do |sample|
        assert_select 'tr td', :text => sample.id, :count => 1
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
    assert_equal 200, received_data['status']
    received_strains = received_data["strains"]
    assert_equal 3, received_strains.count
    assert received_strains.include?([new_strain.id, new_strain.info])
  end

  test "should have age at sampling in sample table" do
    specimen = specimens("running mouse")
    xhr(:get, :existing_samples, {:specimen_ids => "#{specimen.id}"})
    assert_response :success
    assert_select "table#sample_table thead tr th", :text => "Age at sampling", :count => 1
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
end
