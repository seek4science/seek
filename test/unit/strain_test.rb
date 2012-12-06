require 'test_helper'

class StrainTest < ActiveSupport::TestCase
  fixtures :all
  def setup
    User.current_user = Factory(:user)
  end

  def setup
    User.current_user = Factory(:user)
  end

  test "to_rdf" do
    object = Factory(:strain, :organism=>Factory(:organism, :bioportal_concept=>Factory(:bioportal_concept)),:provider_id=>"Dxxu1")
    Factory :assay_organism, :strain=>object, :organism=>object.organism

    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/strains/#{object.id}"), reader.statements.first.subject
    end
  end

  test "assays" do
    ao = Factory(:assay_organism)
    strain = ao.strain
    assert_equal [ao.assay],strain.assays
  end

  test "ncbi uri" do
    strain = Factory(:strain, :organism=>Factory(:organism, :bioportal_concept=>Factory(:bioportal_concept)))
    assert_equal "http://purl.obolibrary.org/obo/NCBITaxon_2287",strain.ncbi_uri

    strain = Factory(:organism)

    assert_nil strain.ncbi_uri
  end

  test "without default" do
    Strain.destroy_all
    org = Factory :organism
    Strain.create :title=>"fred",:is_dummy=>false, :organism=>org, :projects => [Factory(:project)]
    Strain.create :title=>"default",:is_dummy=>true, :organism=>org
    strains=org.strains.without_default
    assert_equal 1,strains.count
    assert_equal "fred",strains.first.title
  end

  test "default strain for organism" do
    Strain.destroy_all
    org = Factory :organism
    strain = nil
    assert_difference("Strain.count") do
      strain = Strain.default_strain_for_organism(org)
      assert_equal("default",strain.title)
      assert_equal org,strain.organism
      assert_equal 1,strain.genotypes.length
      assert_equal 'wild-type',strain.genotypes.first.gene.title
      assert_equal 'wild-type',strain.phenotypes.first.description
      assert strain.is_dummy?
    end

    assert_no_difference("Strain.count") do
        next_strain = Strain.default_strain_for_organism(org)
        assert_equal strain,next_strain
    end
  end

  test "default strain for organism_id" do
    Strain.destroy_all
    org = Factory :organism
    strain = nil
    assert_difference("Strain.count") do
      strain = Strain.default_strain_for_organism(org.id)
      assert_equal("default",strain.title)
      assert_equal org,strain.organism
      assert_equal 1,strain.genotypes.length
      assert_equal 'wild-type',strain.genotypes.first.gene.title
      assert_equal 'wild-type',strain.phenotypes.first.description
      assert strain.is_dummy?
    end

    assert_no_difference("Strain.count") do
        next_strain = Strain.default_strain_for_organism(org.id)
        assert_equal strain,next_strain
    end
  end

  test 'should only allow to delete strain which has no specimen' do
    strain = Factory(:strain)
    assert strain.specimens.empty?
    assert strain.can_delete?

    Factory :specimen, :strain_id => strain.id

    strain.reload
    assert !strain.specimens.empty?
    assert !strain.can_delete?
  end

  test 'should allow to delete strain which has dummy specimen and no sample attach to this specimen' do
    strain = Factory(:strain)
    Factory :specimen, :strain_id => strain.id, :is_dummy => true
    strain.reload

    assert !strain.specimens.empty?
    assert strain.specimens.first.samples.empty?
    assert strain.can_delete?
  end

  test "validation" do
    strain=Strain.new :title => "strain", :projects => [projects(:sysmo_project)], :organism => organisms(:yeast)
    assert strain.valid?

    strain=Strain.new :title => "strain", :projects => [projects(:sysmo_project)]
    assert !strain.valid?

    strain=Strain.new :title => "strain", :organism => organisms(:yeast)
    unless Seek::Config.is_virtualliver
      assert !strain.valid?
    else
      assert strain.valid?
    end

    strain = Strain.new :organism => organisms(:yeast), :projects => [projects(:sysmo_project)]
    assert !strain.valid?

    #dummy strain
    strain = Strain.new :title => 'strain', :organism => organisms(:yeast), :is_dummy => true
    assert strain.valid?
  end

  test 'destroy strain' do
    genotype = Factory(:genotype, :specimen => nil, :strain => nil)
    phenotype = Factory(:phenotype, :specimen => nil, :strain => nil)
    strain = Factory(:strain, :genotypes => [genotype], :phenotypes => [phenotype])
    disable_authorization_checks{strain.destroy}
    assert_equal nil, Strain.find_by_id(strain.id)
    assert_equal nil, Genotype.find_by_id(genotype.id)
    assert_equal nil, Phenotype.find_by_id(phenotype.id)
  end

  test 'when destroying strain, should not destroy genotypes/phenotypes that are linked to specimen' do
      genotype1 = Factory(:genotype, :specimen => nil, :strain => nil)
      genotype2 = Factory(:genotype, :specimen => nil, :strain => nil)
      phenotype1 = Factory(:phenotype, :specimen => nil, :strain => nil)
      phenotype2 = Factory(:phenotype, :specimen => nil, :strain => nil)
      strain = Factory(:strain, :genotypes => [genotype1,genotype2], :phenotypes => [phenotype1,phenotype2])
      specimen = Factory(:specimen,:genotypes => [genotype1], :phenotypes => [phenotype1])
      disable_authorization_checks{strain.destroy}
      assert_equal nil, Strain.find_by_id(strain.id)
      assert_equal nil, Genotype.find_by_id(genotype2.id)
      assert_equal nil, Phenotype.find_by_id(phenotype2.id)
      assert_not_nil Genotype.find_by_id(genotype1.id)
      assert_not_nil Phenotype.find_by_id(phenotype1.id)
  end
end
