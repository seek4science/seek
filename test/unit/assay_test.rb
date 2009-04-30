require 'test_helper'

class AssayTest < ActiveSupport::TestCase
  fixtures :assays,:sops,:assay_types

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))

  end

  test "validation" do
    assay=Assay.new(:title=>"test",:assay_type=>assay_types(:metabolomics))
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
    
  end
end
