require "test_helper"

class SpecimenTest < ActiveSupport::TestCase
  fixtures :all

  test "validation" do
    specimen = Factory :specimen,:donor_number => "DonorNumber"
    #specimen = Specimen.new(:donor_number => "Dying mouse")
    assert specimen.valid?

    specimen.title = nil
    assert !specimen.valid?
  end


end