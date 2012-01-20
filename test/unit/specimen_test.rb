require "test_helper"

class SpecimenTest < ActiveSupport::TestCase
fixtures :all

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
      assert !specimen.valid? if Seek::Config.is_virtualliver

  end

  test "age in weeks" do
    specimen = Factory :specimen,:age => 12
    assert_equal "#{specimen.age} (weeks)",specimen.age_in_weeks
  end

  test "get organism" do
    specimen = Factory :specimen
    assert_not_nil specimen.organism

  end

end
