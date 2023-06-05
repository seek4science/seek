require 'test_helper'

class StrainTest < ActiveSupport::TestCase
  fixtures :all
  def setup
    User.current_user = FactoryBot.create(:user)
  end

  def setup
    User.current_user = FactoryBot.create(:user)
  end

  test 'info' do
    strain = FactoryBot.create(:strain, title: 'CCTV')
    assert_equal 'CCTV (wild-type / wild-type)', strain.info

    genotype = FactoryBot.create(:genotype, gene: FactoryBot.create(:gene, title: 'fff'), modification: FactoryBot.create(:modification, title: 'del'))
    strain.genotypes << genotype

    assert_equal 'CCTV (del fff / wild-type)', strain.info

    genotype = FactoryBot.create(:genotype, gene: FactoryBot.create(:gene, title: 'ggg'), modification: FactoryBot.create(:modification, title: 'ins'))
    strain.genotypes << genotype

    assert_equal 'CCTV (del fff;ins ggg / wild-type)', strain.info

    strain.phenotypes << FactoryBot.create(:phenotype, description: 'yellow beard')

    assert_equal 'CCTV (del fff;ins ggg / yellow beard)', strain.info
  end

  test 'to_rdf' do
    object = FactoryBot.create(:strain, organism: FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept)), provider_id: 'Dxxu1')
    FactoryBot.create :assay_organism, strain: object, organism: object.organism

    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/strains/#{object.id}"), reader.statements.first.subject
    end
  end

  test 'assays' do
    ao = FactoryBot.create(:assay_organism)
    strain = ao.strain
    assert_equal [ao.assay], strain.assays
  end

  test 'ncbi uri' do
    strain = FactoryBot.create(:strain, organism: FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept)))
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2287', strain.ncbi_uri

    strain = FactoryBot.create(:organism)

    assert_nil strain.ncbi_uri
  end

  test 'without default' do
    Strain.destroy_all
    org = FactoryBot.create :organism
    Strain.create title: 'fred', is_dummy: false, organism: org, projects: [FactoryBot.create(:project)]
    Strain.create title: 'default', is_dummy: true, organism: org
    strains = org.strains.without_default
    assert_equal 1, strains.count
    assert_equal 'fred', strains.first.title
  end

  test 'default strain for organism' do
    Strain.destroy_all
    org = FactoryBot.create :organism
    strain = nil
    assert_difference('Strain.count') do
      strain = Strain.default_strain_for_organism(org)
      assert_equal('default', strain.title)
      assert_equal org, strain.organism
      assert_equal 1, strain.genotypes.length
      assert_equal 'wild-type', strain.genotypes.first.gene.title
      assert_equal 'wild-type', strain.phenotypes.first.description
      assert strain.is_dummy?
    end

    assert_no_difference('Strain.count') do
      next_strain = Strain.default_strain_for_organism(org)
      assert_equal strain, next_strain
    end
  end

  test 'default strain for organism_id' do
    Strain.destroy_all
    org = FactoryBot.create :organism
    strain = nil
    assert_difference('Strain.count') do
      strain = Strain.default_strain_for_organism(org.id)
      assert_equal('default', strain.title)
      assert_equal org, strain.organism
      assert_equal 1, strain.genotypes.length
      assert_equal 'wild-type', strain.genotypes.first.gene.title
      assert_equal 'wild-type', strain.phenotypes.first.description
      assert strain.is_dummy?
    end

    assert_no_difference('Strain.count') do
      next_strain = Strain.default_strain_for_organism(org.id)
      assert_equal strain, next_strain
    end
  end

  test 'validation' do
    strain = Strain.new title: 'strain', projects: [projects(:sysmo_project)], organism: organisms(:yeast)
    assert strain.valid?

    strain = Strain.new title: 'strain', projects: [projects(:sysmo_project)]
    assert !strain.valid?

    strain = Strain.new title: 'strain', organism: organisms(:yeast)

    refute strain.valid?

    strain = Strain.new organism: organisms(:yeast), projects: [projects(:sysmo_project)]
    assert !strain.valid?

    # dummy strain
    strain = Strain.new title: 'strain', organism: organisms(:yeast), is_dummy: true
    assert strain.valid?
  end

  test 'destroy strain' do
    genotype = FactoryBot.create(:genotype, strain: nil)
    phenotype = FactoryBot.create(:phenotype, strain: nil)
    strain = FactoryBot.create(:strain, genotypes: [genotype], phenotypes: [phenotype])
    disable_authorization_checks { strain.destroy }
    assert_nil Strain.find_by_id(strain.id)
    assert_nil Genotype.find_by_id(genotype.id)
    assert_nil Phenotype.find_by_id(phenotype.id)
  end
end
