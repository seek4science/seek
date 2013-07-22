require 'test_helper'

class InternationalizationTest < ActiveSupport::TestCase

  test "biosamples renaming" do
    as_not_virtualliver do
       assert_equal "Cell culture", (I18n.t "biosamples.sample_parent_term")
       assert_equal "Culture starting date", (I18n.t "biosamples.specimen_culture_starting_date")
       assert_equal "Age at sampling", (I18n.t "biosamples.sample_age")
       assert_equal "Creators", (I18n.t "biosamples.specimen_creators")
    end
  end

  test "assay" do
    as_not_virtualliver do
      assert_equal "Assay", (I18n.t "assays.assay")
      assert_equal "Experimental assay", (I18n.t "assays.experimental_assay")
      assert_equal "Modelling analysis", (I18n.t "assays.modelling_analysis")
    end
  end

  test "sop" do
    as_not_virtualliver do
      assert_equal "SOP", (I18n.t "sop")
    end
  end

  test "presentation" do
    as_not_virtualliver do
      assert_equal "Presentation", (I18n.t "presentation")
    end
  end

  test "data file" do
    as_not_virtualliver do
      assert_equal "Data file", (I18n.t "data_file")
    end
  end

  test "investigation" do
    as_not_virtualliver do
      assert_equal "Investigation", (I18n.t "investigation")
    end
  end

  test "study" do
    as_not_virtualliver do
      assert_equal "Study", (I18n.t "study")
    end
  end
end