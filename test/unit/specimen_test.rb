require "test_helper"

class SpecimenTest < ActiveSupport::TestCase
fixtures :all

  test "validation" do

      specimen = Factory :specimen, :title => "DonorNumber"
      assert specimen.valid?
      assert_equal "DonorNumber",specimen.title

      specimen.title = nil
      assert !specimen.valid?

      specimen.title = ""
      assert !specimen.valid?

      specimen.reload
      specimen.contributor = nil
      assert !specimen.valid?

      specimen.reload
      specimen.institution= nil
      as_virtualliver do
        assert !specimen.valid?
      end

      as_not_virtualliver do
        assert specimen.valid?
      end
  end

  test "age with unit" do
    specimen = Factory :specimen,:age => 12,:age_unit=>"year"
    assert_equal "12(years)",specimen.age_with_unit
  end

  test "get organism" do
    specimen = Factory :specimen
    assert_not_nil specimen.organism

  end

  test "related people" do
    specimen = Factory :specimen
    specimen.creators = [Factory(:person),Factory(:person)]

    assert_equal specimen.creators, specimen.related_people
  end

  test "genotype_attributes" do
    specimen = Factory :specimen
    User.current_user = specimen.contributor
    specimen.genotypes_attributes = {0 => {:gene_attributes => {:title => 'test gene'}, :modification_attributes => {:title => 'test modification'}}, 1 => {:gene_attributes => {:title => 'test gene2'}, :modification_attributes => {:title => 'test modification2'}}}
    assert specimen.genotypes.count, 2
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene' && g.modification.title == 'test modification'}
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene2' && g.modification.title == 'test modification2'}

    assert specimen.save
    specimen.reload
    assert specimen.genotypes.count, 2
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene' && g.modification.title == 'test modification'}
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene2' && g.modification.title == 'test modification2'}

    end

  test "phenotype_attributes" do
    specimen = Factory :specimen
    User.current_user = specimen.contributor
    specimen.phenotypes_attributes = {0 => {:description => 'test phenotype'}, 1 => {:description => 'test phenotype2'}}
    assert specimen.phenotypes.count, 2
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype'}
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype2'}

    assert specimen.save
    specimen.reload
    assert specimen.phenotypes.count, 2
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype'}
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype2'}
  end

end
