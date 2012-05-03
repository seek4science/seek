require 'test_helper'

class StrainTest < ActiveSupport::TestCase

  test "without default" do
    Strain.destroy_all
    org = Factory :organism
    Strain.create :title=>"fred",:is_dummy=>false, :organism=>org
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
      assert_equal 1,strain.genotypes.count
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
      assert_equal 1,strain.genotypes.count
      assert_equal 'wild-type',strain.genotypes.first.gene.title
      assert_equal 'wild-type',strain.phenotypes.first.description
      assert strain.is_dummy?
    end

    assert_no_difference("Strain.count") do
        next_strain = Strain.default_strain_for_organism(org.id)
        assert_equal strain,next_strain
    end
  end

end
