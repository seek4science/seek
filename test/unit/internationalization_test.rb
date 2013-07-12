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

  test "assay" do
    as_not_virtualliver do
      assert_equal "Assay", (I18n.t "assay.assay")
      assert_equal "Experimental Assay", (I18n.t "assay.experimental_assay")
      assert_equal "Modelling Analysis", (I18n.t "assay.modelling_analysis")
    end
  end

end