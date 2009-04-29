require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  fixtures :studies,:assays,:investigations,:projects,:technology_types,:assay_types

  test "associations" do
    study=studies(:metabolomics_study)
    assert_equal "A Metabolomics Study",study.title

    assert_not_nil study.assays
    assert_equal 1,study.assays.size
    assert_not_nil study.investigation.project

    assert_equal "Metabolomics Assay",study.assays.first.title
    assert_equal projects(:sysmo_project),study.investigation.project
    
    assert_equal assay_types(:metabolomics),study.assays.first.assay_type


  end

  test "project from topic" do
    study=studies(:metabolomics_study)
    assert_equal projects(:sysmo_project), study.project
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
  end
  
end
