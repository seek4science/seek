require File.dirname(__FILE__) + '/../test_helper'

class AssayTest < ActiveSupport::TestCase
  fixtures :all

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop).versions.first)
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).versions.first)
  end

  test "is_modelling" do
    assay=assays(:metabolomics_assay)
    assert !assay.is_modelling?
    assay.assay_class=assay_classes(:modelling_assay_class)
    assay.save!
    assert assay.is_modelling?
  end

  test "is_experimental" do
    assay=assays(:metabolomics_assay)
    assert assay.is_experimental?
    assay.assay_class=assay_classes(:modelling_assay_class)
    assay.save!
    assert !assay.is_experimental?
  end

  test "related investigation" do
    assay=assays(:metabolomics_assay)
    assert_not_nil assay.investigation
    assert_equal investigations(:metabolomics_investigation),assay.investigation
  end

  test "related project" do
    assay=assays(:metabolomics_assay)
    assert_not_nil assay.project
    assert_equal projects(:sysmo_project),assay.project
  end
  

  test "validation" do
    assay=Assay.new(:title=>"test",
      :assay_type=>assay_types(:metabolomics),
      :technology_type=>technology_types(:gas_chromatography),
      :study => studies(:metabolomics_study),
      :owner => people(:person_for_model_owner),
      :assay_class => assay_classes(:experimental_assay_class))
    
    assert assay.valid?

    assay.title=""
    assert !assay.valid?

    assay.title=nil
    assert !assay.valid?

    assay.title=assays(:metabolomics_assay).title
    assert !assay.valid?

    assay.title="test"
    assay.assay_type=nil
    assert !assay.valid?

    assay.assay_type=assay_types(:metabolomics)

    assert assay.valid?

    assay.study=nil
    assert !assay.valid?
    assay.study=studies(:metabolomics_study)

    assay.technology_type=nil
    assert !assay.valid?

    assay.technology_type=technology_types(:gas_chromatography)
    assert assay.valid?

    assay.owner=nil
    assert !assay.valid?

    assay.owner=people(:person_for_model_owner)

    #an modelling assay can be valid without a technology type
    assay.assay_class=assay_classes(:modelling_assay_class)
    assay.technology_type=nil
    assert assay.valid?
    
  end

  test "assay with no study has nil study and project" do
    a=assays(:assay_with_no_study_or_files)
    assert_nil a.study
    assert_nil a.project
  end

  test "can delete?" do
    assert assays(:assay_with_no_study_or_files).can_delete?(users(:model_owner))
    assert assays(:assay_with_just_a_study).can_delete?(users(:model_owner))
    assert !assays(:assay_with_no_study_but_has_some_files).can_delete?(users(:model_owner))
    assert !assays(:assay_with_no_study_but_has_some_sops).can_delete?(users(:model_owner))
  end

  test "assets" do
    assay=assays(:metabolomics_assay)
    assert_equal 3,assay.assets.size,"should be 2 sops and 1 data file"
  end

  test "sops" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop).find_version(1))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).find_version(1))
  end

  test "data_files" do
    assay=assays(:metabolomics_assay)
    assert_equal 1,assay.data_files.size
    assert assay.data_files.include?(data_files(:picture).find_version(1))
  end
  
  test "relationship_type attached to assay's datafiles" do
    assay=assays(:metabolomics_assay)
    assay.relate(assets(:asset_for_datafile), relationship_types(:test_data))
    
    df = assay.data_files.last
    assert_equal data_files(:picture).latest_version, df
    assert_equal df.relationship_type, relationship_types(:test_data) 
  end

  test "organisms association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.assay_organisms.count
    assert_equal 2,assay.organisms.count
    assert assay.organisms.include?(organisms(:yeast))
    assert assay.organisms.include?(organisms(:Saccharomyces_cerevisiae))
  end

  test "associate organism" do
    assay=assays(:metabolomics_assay)
    organism=organisms(:yeast)
    #test with numeric ID
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism.id)
    end

    #with String ID
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism.id.to_s)
    end

    #with Organism object
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism)
    end

    #with a culture growth
    assay.assay_organisms.clear
    assay.save!
    cg=culture_growth_types(:batch)
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism,nil,cg)
    end
    assay.reload
    assert_equal cg,assay.assay_organisms.first.culture_growth_type

  end

  test "disassociating organisms removes AssayOrganism" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.assay_organisms.count
    assert_difference("AssayOrganism.count",-2) do
      assay.assay_organisms.clear
      assay.save!
    end
    
  end

  test "associate organism with strain" do
    assay=assays(:metabolomics_assay2)
    organism=organisms(:Streptomyces_coelicolor)
    assert_equal 0,assay.assay_organisms.count,"This test relies on this assay having no organisms"
    assert_equal 0,organism.strains.count, "This test relies on this organism having no strains"

    assert_difference("AssayOrganism.count") do
      assert_difference("Strain.count") do
        assay.associate_organism(organism,"FFFF")
      end
    end

    assert_difference("AssayOrganism.count") do
      assert_no_difference("Strain.count") do
        assay.associate_organism(organism,"FFFF")
      end
    end

    organism=organisms(:yeast)
    assert_difference("AssayOrganism.count") do
      assert_difference("Strain.count") do
        assay.associate_organism(organism,"FFFF")
      end
    end

  end

end
