require 'test_helper'

class TreatmentsTest < ActiveSupport::TestCase

  include SysMODB::SpreadsheetExtractor

  test "extract normal case" do
    xml = xml_for_file("treatments-normal-case.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 4,treatment.values["pH"].count
    assert_equal 4,treatment.values["Dilution_rate"].count

    assert_equal ["6.5","6.6","7.5","7.6"],treatment.values["pH"]
    assert_equal ["0.25","0.15","0.05","0.45"],treatment.values["Dilution_rate"]

    assert_equal 4, treatment.sample_names.count
    assert_equal ["samplea","sampleb","samplec","sampled"],treatment.sample_names

  end

  test "extract when blanks in sheet" do
    xml = xml_for_file("treatments-with-blanks.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 4,treatment.values["pH"].count
    assert_equal 4,treatment.values["Dilution_rate"].count

    assert_equal ["6.5","","7.5","7.6"],treatment.values["pH"]
    assert_equal ["0.25","0.15","0.05",""],treatment.values["Dilution_rate"]

    assert_equal 4, treatment.sample_names.count
    assert_equal ["samplea","sampleb","","sampled"],treatment.sample_names
  end

  test "extract samples from different column" do
    xml = xml_for_file("treatments-with-samples-different-column.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 4,treatment.values["pH"].count
    assert_equal 4,treatment.values["Dilution_rate"].count

    assert_equal ["6.5","2.2","7.5","7.6"],treatment.values["pH"]
    assert_equal ["0.25","0.15","0.05","1.6"],treatment.values["Dilution_rate"]

    assert_equal 4, treatment.sample_names.count
    assert_equal ["samplea","sampleb","samplec","sampled"],treatment.sample_names
  end

  test "extract when no sample names" do
    xml = xml_for_file("treatments-with-no-sample-names.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 2,treatment.values.keys.count
    assert_equal ["Dilution_rate","pH"],treatment.values.keys.sort
    assert_equal 4,treatment.values["pH"].count
    assert_equal 4,treatment.values["Dilution_rate"].count

    assert_equal ["6.5","2.2","7.5","7.6"],treatment.values["pH"]
    assert_equal ["0.25","0.15","0.05","1.6"],treatment.values["Dilution_rate"]

    assert_equal 4, treatment.sample_names.count
    assert_equal ["","","",""],treatment.sample_names
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

  test "extract from misnamed sample sheet" do
    xml = xml_for_file("treatments-mis-named-sample-sheet.xls")
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

  test "extract treatments last columns" do
    xml = xml_for_file("treatments-last-column.xls")
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

  test "extract additional treatment columns" do
    xml = xml_for_file("treatments-extra-column.xls")
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

  test "extract from katys populated problematic file" do
    xml = xml_for_file("JERM_2DGel_SEEKJERM_edited.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml
    assert_equal 1,treatment.sample_names.count
    assert_equal "",treatment.sample_names.first
    assert_equal 2, treatment.values.keys.count
    assert_equal ["activity","growth_medium"],treatment.values.keys.sort
    assert_equal 1,treatment.values["activity"].count
    assert_equal 1,treatment.values["growth_medium"].count
    assert_equal "25.0",treatment.values["activity"].first
    assert_equal "raspberry jam",treatment.values["growth_medium"].first
  end

  test "extract from katys original problematic file" do
    xml = xml_for_file("JERM_2DGel_SEEKJERM_original.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml
    assert_equal 0,treatment.sample_names.count
    assert_equal 2, treatment.values.keys.count
    assert_equal ["e.g Growth medium","e.g temperature"],treatment.values.keys.sort
    assert_equal 0,treatment.values["e.g Growth medium"].count
    assert_equal 0,treatment.values["e.g temperature"].count
  end

  test "extract no treatments" do
    xml = xml_for_file("small-test-spreadsheet.xls")
    assert xml.include?("workbook")
    treatment = Seek::Treatments.new xml

    assert_equal 0,treatment.values.keys.count

    assert_equal 0, treatment.sample_names.count

  end

  test "extract nil xml" do
    treatment = Seek::Treatments.new nil

    assert_equal 0,treatment.values.keys.count

    assert_equal 0, treatment.sample_names.count
  end

  test "extract invalid xml" do
    treatment = Seek::Treatments.new "this is not xml"

    assert_equal 0,treatment.values.keys.count

    assert_equal 0, treatment.sample_names.count
  end

  test "initialize empty treatments" do
    treatment = Seek::Treatments.new

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