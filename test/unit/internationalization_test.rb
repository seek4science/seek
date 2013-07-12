require 'test_helper'

class InternationalizationTest < ActiveSupport::TestCase

  test "biosamples renaming" do
    as_not_virtualliver do
       assert_equal "cell culture", (I18n.t "biosamples.sample_parent_term")
       assert_equal "Culture starting date", (I18n.t "biosamples.specimen_culture_starting_date")
       assert_equal "Age at sampling", (I18n.t "biosamples.sample_age")
       assert_equal "Creators", (I18n.t "biosamples.specimen_creators")
    end
  end

end