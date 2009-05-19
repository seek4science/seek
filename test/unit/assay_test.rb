require 'test_helper'

class AssayTest < ActiveSupport::TestCase
  fixtures :assays,:sops,:assay_types,:technology_types,:projects,:studies,:investigations

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))

  end

  test "related projects" do
    assay=assays(:metabolomics_assay)
    assert_equal 1,assay.projects.size
    assert_equal projects(:sysmo_project),assay.projects.first
  end

  test "multiple_related_projects" do
    assay=assays(:assay_with_2_projects)
    assert_equal 2,assay.projects.size
    assert assay.projects.include?(projects(:sysmo_project))
    assert assay.projects.include?(projects(:moses_project))
  end

  test "validation" do
    assay=Assay.new(:title=>"test",
      :assay_type=>assay_types(:metabolomics),
      :technology_type=>technology_types(:gas_chromatography))
    
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
    assay.technology_type=nil
    assert !assay.valid?
    
  end
end
