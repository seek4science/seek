require 'test_helper'

class TreatmentsTest < ActiveSupport::TestCase
  include SysMODB::SpreadsheetExtractor

  test "extract test1" do
    xml = xml_for_file("treatments-test1.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 19,treatment.values["pH"].count
    assert_equal 19,treatment.values["Dilution_rate"].count
    assert_equal "6.5",treatment.values["pH"].first
    assert_equal "9.5",treatment.values["pH"].last

    assert_equal "0.25",treatment.values["Dilution_rate"].first
    assert_equal "0.15",treatment.values["Dilution_rate"].last

    assert_equal 19, treatment.sample_names.count
    assert_equal "1.0",treatment.sample_names.first
    assert_equal "17.0",treatment.sample_names.last

  end

  test "extract when treatment not in first row" do
    xml = xml_for_file("treatments-not-in-first-row.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 19,treatment.values["pH"].count
    assert_equal 19,treatment.values["Dilution_rate"].count
    assert_equal "6.5",treatment.values["pH"].first
    assert_equal "9.5",treatment.values["pH"].last

    assert_equal "0.25",treatment.values["Dilution_rate"].first
    assert_equal "0.15",treatment.values["Dilution_rate"].last

    assert_equal 19, treatment.sample_names.count
    assert_equal "1.0",treatment.sample_names.first
    assert_equal "17.0",treatment.sample_names.last

  end

  test "extract test2" do
    xml = xml_for_file("treatments-test2.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 19,treatment.values["pH"].count
    assert_equal 19,treatment.values["Dilution_rate"].count
    assert_equal "6.5",treatment.values["pH"].first
    assert_equal "9.5",treatment.values["pH"].last

    assert_equal "0.25",treatment.values["Dilution_rate"].first
    assert_equal "0.15",treatment.values["Dilution_rate"].last

    assert_equal 19, treatment.sample_names.count
    assert_equal "1.0",treatment.sample_names.first
    assert_equal "17.0",treatment.sample_names.last

  end

  test "extract test3" do
    xml = xml_for_file("treatments-test3.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 19,treatment.values["pH"].count
    assert_equal 19,treatment.values["Dilution_rate"].count
    assert_equal "6.5",treatment.values["pH"].first
    assert_equal "9.5",treatment.values["pH"].last

    assert_equal "0.25",treatment.values["Dilution_rate"].first
    assert_equal "0.15",treatment.values["Dilution_rate"].last

    assert_equal 19, treatment.sample_names.count
    assert_equal "1.0",treatment.sample_names.first
    assert_equal "17.0",treatment.sample_names.last

  end

  test "extract test4" do
    xml = xml_for_file("treatments-test4.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 3,treatment.values.keys.count
    assert_equal ["Buffer","Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 19,treatment.values["pH"].count
    assert_equal 19,treatment.values["Dilution_rate"].count
    assert_equal 19,treatment.values["Buffer"].count
    assert_equal "6.5",treatment.values["pH"].first
    assert_equal "9.5",treatment.values["pH"].last

    assert_equal "0.25",treatment.values["Dilution_rate"].first
    assert_equal "0.15",treatment.values["Dilution_rate"].last

    assert_equal "1.0",treatment.values["Buffer"].first
    assert_equal "5.0",treatment.values["Buffer"].last

    assert_equal 19, treatment.sample_names.count
    assert_equal "1.0",treatment.sample_names.first
    assert_equal "17.0",treatment.sample_names.last

  end

  test "extract no treatments" do
    xml = xml_for_file("small-test-spreadsheet.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 0,treatment.values.keys.count

    assert_equal 0, treatment.sample_names.count

  end

  private

  def xml_for_file filename
    path = File.join(Rails.root,"test","fixtures","files",filename)
    f=open path
    spreadsheet_to_xml f
  end

end