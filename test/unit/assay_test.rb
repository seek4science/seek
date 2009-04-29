require 'test_helper'

class AssayTest < ActiveSupport::TestCase
  fixtures :all

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy))

  end
end
