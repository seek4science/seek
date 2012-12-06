require 'test_helper'
require 'libxml'

class RDFGenerationTest < ActiveSupport::TestCase

  include RightField

  test "rightfield rdf generation" do
    df=Factory :rightfield_annotated_datafile
    assert_not_nil(df.content_blob)
    rdf = generate_rightfield_rdf(df)
    assert_not_nil(rdf)


    #just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert_equal 2,reader.statements.count
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test "save rdf" do
    assay = Factory(:assay, :policy=>Factory(:public_policy))
    assert assay.can_view?(nil)
    tmpdir= File.join(Dir.tmpdir,"seek-rdf-tests-#{$$}")
    expected_rdf_file = File.join(tmpdir,"public","Assay-#{assay.id}.rdf")
    puts tmpdir
    FileUtils.rm expected_rdf_file if File.exists?(expected_rdf_file)

    assay.save_rdf tmpdir

    assert File.exists?(expected_rdf_file)
    rdf=""
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal assay.to_rdf,rdf
    FileUtils.rm expected_rdf_file
    assert !File.exists?(expected_rdf_file)
  end

  test "save private rdf" do
    sop = Factory(:sop, :policy=>Factory(:private_policy))
    assert !sop.can_view?(nil)
    tmpdir= File.join(Dir.tmpdir,"seek-rdf-tests-#{$$}")
    expected_rdf_file = File.join(tmpdir,"private","Sop-#{sop.id}.rdf")
    puts tmpdir
    FileUtils.rm expected_rdf_file if File.exists?(expected_rdf_file)

    sop.save_rdf tmpdir

    assert File.exists?(expected_rdf_file)
    rdf=""
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal sop.to_rdf,rdf
    FileUtils.rm expected_rdf_file
    assert !File.exists?(expected_rdf_file)
  end

  test "rightfield rdf graph generation" do
    df=Factory :rightfield_annotated_datafile
    rdf = generate_rightfield_rdf_graph(df)
    assert_not_nil rdf
    assert rdf.is_a?(RDF::Graph)
    assert_equal 2,rdf.statements.count
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), rdf.statements.first.subject

  end

  test "datafile to_rdf" do
    df=Factory :rightfield_annotated_datafile
    rdf = df.to_rdf
    assert_not_nil rdf
    #just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test "non spreadsheet datafile to_rdf" do
    df=Factory :non_spreadsheet_datafile
    rdf = df.to_rdf
    assert_not_nil rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test "xlsx datafile to_rdf" do
    df=Factory :xlsx_spreadsheet_datafile

    rdf = df.to_rdf
    assert_not_nil rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

end