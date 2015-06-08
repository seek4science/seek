require "test_helper"

class SpecimenTest < ActiveSupport::TestCase

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

      specimen.reload
      specimen.strain = nil
      assert !specimen.valid?
  end

  test "to rdf" do
    object = Factory :specimen, :contributor=>Factory(:person), :lab_internal_number=>"Asda",:sample_ids=>[Factory(:sample).id],
                     :strain=>Factory(:strain),:comments=>"blah blah",:culture_growth_type=>Factory(:culture_growth_type)

    object.reload
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/specimens/#{object.id}"), reader.statements.first.subject
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

  test "related sops" do
    User.with_current_user Factory(:user) do
      specimen = Factory :specimen, :contributor => User.current_user.person
      sop = Factory :sop, :contributor => User.current_user.person
      specimen.build_sops [sop.id]
      assert specimen.save

      specimen.reload

      assert_equal [sop], specimen.sops
    end
  end

  test "cleans up relationship with sop when either deleted" do
    person = Factory(:person)
    User.with_current_user person.user do
      specimen = Factory :specimen, :contributor => person
      sop = Factory :sop, :contributor => person
      specimen.build_sops [sop.id]
      assert specimen.save
      specimen.reload
      refute specimen.sop_versions.empty?
      assert_difference("SopSpecimen.count",-1) do
        sop.destroy
      end
      specimen.reload
      assert specimen.sops.empty?
      assert specimen.sop_versions.empty?

      #now delete specimen
      sop = Factory :sop, :contributor => person
      specimen.build_sops [sop.id]
      assert specimen.save
      sop.reload
      refute sop.specimens.empty?
      assert_difference("SopSpecimen.count",-1) do
        specimen.destroy
      end
      sop.reload
      assert sop.specimens.empty?
    end
  end

  test "genotype_attributes" do
    specimen = Factory :specimen
    User.current_user = specimen.contributor
    specimen.genotypes_attributes = {0 => {:gene_attributes => {:title => 'test gene'}, :modification_attributes => {:title => 'test modification'}}, 1 => {:gene_attributes => {:title => 'test gene2'}, :modification_attributes => {:title => 'test modification2'}}}

    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene' && g.modification.title == 'test modification'}
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene2' && g.modification.title == 'test modification2'}

    assert specimen.save
    specimen = Specimen.find(specimen.id)
    assert_equal 2, specimen.genotypes.count
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene' && g.modification.title == 'test modification'}
    assert specimen.genotypes.detect {|g| g.gene.title == 'test gene2' && g.modification.title == 'test modification2'}

    end

  test "phenotype_attributes" do
    specimen = Factory :specimen
    User.current_user = specimen.contributor
    specimen.phenotypes_attributes = {0 => {:description => 'test phenotype'}, 1 => {:description => 'test phenotype2'}}

    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype'}
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype2'}

    assert specimen.save
    specimen.reload
    assert_equal 2, specimen.phenotypes.count
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype'}
    assert specimen.phenotypes.detect {|p| p.description == 'test phenotype2'}
  end

  test 'destroy specimen' do
    genotype = Factory(:genotype, :specimen => nil, :strain => nil)
    phenotype = Factory(:phenotype, :specimen => nil, :strain => nil)
    specimen = Factory(:specimen, :genotypes => [genotype], :phenotypes => [phenotype])
    disable_authorization_checks{specimen.destroy}
    assert_nil Strain.find_by_id(specimen.id)
    assert_nil Genotype.find_by_id(genotype.id)
    assert_nil Phenotype.find_by_id(phenotype.id)
  end

  test 'when destroying specimen, should not destroy genotypes/phenotypes that are linked to strain' do
      genotype1 = Factory(:genotype, :specimen => nil, :strain => nil)
      genotype2 = Factory(:genotype, :specimen => nil, :strain => nil)
      phenotype1 = Factory(:phenotype, :specimen => nil, :strain => nil)
      phenotype2 = Factory(:phenotype, :specimen => nil, :strain => nil)
      strain = Factory(:strain, :genotypes => [genotype1], :phenotypes => [phenotype1] )
      specimen = Factory(:specimen, :genotypes => [genotype1,genotype2], :phenotypes => [phenotype1,phenotype2])
      disable_authorization_checks{specimen.destroy}
      assert_equal nil, Specimen.find_by_id(specimen.id)
      assert_equal nil, Genotype.find_by_id(genotype2.id)
      assert_equal nil, Phenotype.find_by_id(phenotype2.id)
      assert_not_nil Genotype.find_by_id(genotype1.id)
      assert_not_nil Phenotype.find_by_id(phenotype1.id)
  end

  test "specimen-sop associations" do
    User.with_current_user Factory(:user) do
      specimen = Factory :specimen, :contributor => User.current_user
      sop = Factory :sop, :contributor => User.current_user
      specimen.build_sops [sop.id]
      assert specimen.valid?
      assert specimen.save
      specimen.reload

      assert_equal 1, specimen.sops.count
      assert_equal sop, specimen.sops.first
      assert_equal 1, specimen.sop_versions.count
      assert_equal sop.latest_version, specimen.sop_versions.first
    end
  end

  test "specimen-sop associations when sop has multiple versions" do
    User.with_current_user Factory(:user) do
      specimen = Factory :specimen, :contributor => User.current_user
      sop = Factory :sop, :contributor => User.current_user
      sop_version_2 = Factory(:sop_version, :sop => sop)
      assert_equal 2, sop.versions.count
      assert_equal sop_version_2, sop.latest_version

      specimen.build_sops [sop.id]
      assert specimen.valid?
      assert specimen.save

      specimen.reload

      assert_equal 1, specimen.sops.count
      assert_equal sop, specimen.sops.first
      assert_equal 1, specimen.sop_versions.count
      assert_equal sop_version_2, specimen.sop_versions.first

    end
  end

  test "associated treatments" do
    treatment = Factory(:treatment)
    refute_nil treatment.specimen
    specimen = treatment.specimen
    treatment2 = Factory(:treatment,:specimen=>specimen)
    specimen.reload
    assert_equal 2,specimen.treatments.size
    assert_include specimen.treatments,treatment
    assert_include specimen.treatments,treatment2

    #dependent destroy
    assert_difference('Treatment.count',-2) do
      assert_difference('Specimen.count',-1) do
        disable_authorization_checks do
          specimen.destroy
        end
      end
    end
    assert_nil Treatment.find_by_id(treatment.id)
    assert_nil Treatment.find_by_id(treatment2.id)
  end
end
