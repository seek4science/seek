require 'test_helper'
require 'libxml'

class RDFGenerationTest < ActiveSupport::TestCase
  include RightField

  test 'rightfield rdf generation' do
    df = FactoryBot.create :rightfield_annotated_datafile
    refute_nil(df.content_blob)
    rdf = generate_rightfield_rdf(df)
    refute_nil(rdf)

    # just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert_equal 2, reader.statements.count
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'rdf storage path' do
    public = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    assert_equal File.join(Rails.root, 'tmp/testing-filestore/rdf/public', "Assay-test-#{public.id}.rdf"), public.rdf_storage_path

    private = FactoryBot.create(:assay, policy: FactoryBot.create(:private_policy))
    assert_equal File.join(Rails.root, 'tmp/testing-filestore/rdf/private', "Assay-test-#{private.id}.rdf"), private.rdf_storage_path
  end

  test 'save rdf file' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
    assert assay.can_view?(nil)

    expected_rdf_file = File.join(Rails.root, 'tmp/testing-filestore/rdf/public', "Assay-test-#{assay.id}.rdf")
    FileUtils.rm expected_rdf_file if File.exist?(expected_rdf_file)

    assay.save_rdf_file

    assert File.exist?(expected_rdf_file)
    rdf = ''
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal assay.to_rdf, rdf
    FileUtils.rm expected_rdf_file
    assert !File.exist?(expected_rdf_file)
  end

  test 'rdf with problem excel file' do
    # a file that was found to cause an error during the RightField part of the RDF generation.
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:spreadsheet_content_blob, data: File.new("#{Rails.root}/test/fixtures/files/test_file_FakStudied_OK.xls", 'rb').read))
    rdf = df.to_rdf
    assert_not_nil(rdf)

    # just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'save private rdf' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))
    assert !sop.can_view?(nil)

    expected_rdf_file = File.join(Rails.root, 'tmp/testing-filestore/rdf/private', "Sop-test-#{sop.id}.rdf")
    FileUtils.rm expected_rdf_file if File.exist?(expected_rdf_file)

    sop.save_rdf_file

    assert File.exist?(expected_rdf_file)
    rdf = ''
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal sop.to_rdf, rdf
    FileUtils.rm expected_rdf_file
    assert !File.exist?(expected_rdf_file)
  end

  test 'rdf moves from public to private when permissions change' do
    User.with_current_user FactoryBot.create(:user) do
      assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))
      assert assay.can_view?(nil)

      public_rdf_file = File.join(Rails.root, 'tmp/testing-filestore/rdf/public', "Assay-test-#{assay.id}.rdf")
      private_rdf_file = File.join(Rails.root, 'tmp/testing-filestore/rdf/private', "Assay-test-#{assay.id}.rdf")
      FileUtils.rm public_rdf_file if File.exist?(public_rdf_file)
      FileUtils.rm private_rdf_file if File.exist?(private_rdf_file)

      file = assay.save_rdf_file
      assert_equal public_rdf_file, file

      assert File.exist?(public_rdf_file)
      assert !File.exist?(private_rdf_file)

      assay.policy = FactoryBot.create(:private_policy)
      disable_authorization_checks do
        assay.save!
      end

      assert !assay.can_view?(nil)
      file = assay.save_rdf_file
      assert_equal private_rdf_file, file

      assert File.exist?(private_rdf_file)
      assert !File.exist?(public_rdf_file)

      assay.policy = FactoryBot.create(:public_policy)
      disable_authorization_checks do
        assay.save!
      end

      assert assay.can_view?(nil)
      file = assay.save_rdf_file
      assert_equal public_rdf_file, file

      assert File.exist?(public_rdf_file)
      assert !File.exist?(private_rdf_file)
    end
  end

  test 'rightfield rdf graph generation' do
    df = FactoryBot.create :rightfield_annotated_datafile
    rdf = generate_rightfield_rdf_graph(df)
    assert_not_nil rdf
    assert rdf.is_a?(RDF::Graph)
    assert_equal 2, rdf.statements.count
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), rdf.statements.first.subject
  end

  test 'datafile to_rdf' do
    df = FactoryBot.create :rightfield_annotated_datafile
    rdf = df.to_rdf
    assert_not_nil rdf
    # just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'non spreadsheet datafile to_rdf' do
    df = FactoryBot.create :non_spreadsheet_datafile
    rdf = df.to_rdf
    assert_not_nil rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'xlsx datafile to_rdf' do
    df = FactoryBot.create :xlsx_spreadsheet_datafile

    rdf = df.to_rdf
    assert_not_nil rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'rdf type uri' do
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Data'), FactoryBot.create(:data_file).rdf_type_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Model'), FactoryBot.create(:model).rdf_type_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#SOP'), FactoryBot.create(:sop).rdf_type_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Experimental_assay'), FactoryBot.create(:experimental_assay).rdf_type_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Modelling_analysis'), FactoryBot.create(:modelling_assay).rdf_type_uri
    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Organism'), FactoryBot.create(:organism).rdf_type_uri


    assert_equal RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Simulation_data'), FactoryBot.create(:data_file,simulation_data:true).rdf_type_uri

  end

  test 'rdf_seek_id' do
    df = FactoryBot.create(:data_file)
    assert_equal "http://localhost:3000/data_files/#{df.id}",df.rdf_seek_id
  end

  test 'rdf_supported?' do
    assert FactoryBot.create(:person).rdf_supported?
    assert FactoryBot.create(:assay).rdf_supported?
    assert FactoryBot.create(:data_file).rdf_supported?


    refute FactoryBot.create(:event).rdf_supported?
    refute FactoryBot.create(:institution).rdf_supported?
    refute FactoryBot.create(:document).rdf_supported?
  end

end
