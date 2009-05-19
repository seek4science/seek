require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  
  fixtures :studies,:assays,:investigations,:projects,:technology_types,:assay_types,:people,:sops

  test "associations" do
    study=studies(:metabolomics_study)
    assert_equal "A Metabolomics Study",study.title

    assert_not_nil study.assays
    assert_equal 1,study.assays.size
    assert_not_nil study.investigation.project

    assert study.assays.include?(assays(:metabolomics_assay))
    
    assert_equal projects(:sysmo_project),study.investigation.project
    assert_equal projects(:sysmo_project),study.project
    
    assert_equal assay_types(:metabolomics),study.assays.first.assay_type

  end

  test "sops through assays" do
    study=studies(:metabolomics_study)
    assert_equal 2,study.sops.size
    assert study.sops.include?(sops(:my_first_sop))
    assert study.sops.include?(sops(:sop_with_fully_public_policy))
    
    #study with 2 assays that have overlapping sops. Checks that the sops aren't dupliced.
    study=studies(:study_with_overlapping_assay_sops)
    assert_equal 3,study.sops.size
    assert study.sops.include?(sops(:my_first_sop))
    assert study.sops.include?(sops(:sop_with_fully_public_policy))
    assert study.sops.include?(sops(:sop_for_test_with_workgroups))
  end

  test "person responisble" do
    study=studies(:metabolomics_study)
    assert_equal people(:person_without_group),study.person_responsible
  end

  test "project from investigation" do
    study=studies(:metabolomics_study)
    assert_equal projects(:sysmo_project), study.project
    assert_not_nil study.project.name
  end

  test "validation" do
    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation))
    assert s.valid?

    s.title=nil
    assert !s.valid?
    s.title
    assert !s.valid?

    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation))
    s.investigation=nil
    assert !s.valid?

    #duplicate title
    s=Study.new(:title=>"A Metabolomics Study",:investigation=>investigations(:metabolomics_investigation))
    assert !s.valid?

  end
  
end
