require "test_helper"

class SpecimenTest < ActiveSupport::TestCase
  fixtures :all

  test "validation" do
    specimen = Factory :specimen, :donor_number => "DonorNumber"
    assert specimen.valid?
    assert_equal "DonorNumber",specimen.donor_number

    specimen.donor_number = nil
    assert !specimen.valid?

    specimen.donor_number = ""
    assert !specimen.valid?

    specimen.reload
    specimen.contributor = nil
    assert !specimen.valid?


    specimen.reload
    specimen.project= nil
    assert !specimen.valid?

    specimen.reload
    specimen.institution= nil
    assert !specimen.valid?
  end

  test "age in weeks" do
    specimen = Factory :specimen,:age => 12
    assert_equal "#{specimen.age} (weeks)",specimen.age_in_weeks
  end

end