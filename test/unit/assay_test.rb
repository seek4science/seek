require 'test_helper'

class AssayTest < ActiveSupport::TestCase
  fixtures :assays,:sops,:assay_types,:technology_types,:projects,:studies,:investigations

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))

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

  test "assay with no study has nil study and project" do
    a=assays(:assay_with_no_study)
    assert_nil a.study
    assert_nil a.project
  end

end
