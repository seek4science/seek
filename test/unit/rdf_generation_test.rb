require 'test_helper'
require 'libxml'

class RDFGenerationTest < ActiveSupport::TestCase
  include Rightfield::Rightfield

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
    refute_nil rdf

    # just checks it is valid and contains some statements
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), graph.statements.first.subject
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
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end

    assert graph.statements.count > 0
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), graph.statements.first.subject

  end

  test 'non spreadsheet datafile to_rdf' do
    df = FactoryBot.create :non_spreadsheet_datafile
    rdf = df.to_rdf
    assert_not_nil rdf

    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert graph.statements.count > 0
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), graph.statements.first.subject

  end

  test 'xlsx datafile to_rdf' do
    df = FactoryBot.create :xlsx_spreadsheet_datafile

    rdf = df.to_rdf
    assert_not_nil rdf

    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert graph.statements.count > 0
    assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), graph.statements.first.subject

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

  # ---------------------------------------------------------------------------
  # Nested extended metadata
  # ---------------------------------------------------------------------------

  test 'linked extended metadata single emits blank node with nested triples' do
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_single_nested_emt))
    em.set_attribute_value('retention_period', { 'start_date' => '2020-01-01', 'end_date' => '2030-12-31' })
    df = FactoryBot.create(:data_file, extended_metadata: em)
    graph = parse_rdf(df.to_rdf)
    sub = RDF::URI(df.rdf_resource.to_s)

    outer = graph.query([sub, RDF::URI('http://example.org/retentionPeriod'), nil]).to_a
    assert_equal 1, outer.size, 'Expected one retentionPeriod triple'
    blank = outer.first.object
    assert blank.node?, "Expected a blank node for retentionPeriod, got: #{blank.inspect}"
    starts = graph.query([blank, RDF::URI('http://example.org/startDate'), nil]).map { |s| s.object.to_s }
    assert_equal ['2020-01-01'], starts
    ends = graph.query([blank, RDF::URI('http://example.org/endDate'), nil]).map { |s| s.object.to_s }
    assert_equal ['2030-12-31'], ends
  end

  test 'linked extended metadata multi emits one blank node per item' do
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_multi_nested_emt))
    contacts = [{ 'name' => 'Alice', 'email' => 'alice@example.org' },
                { 'name' => 'Bob', 'email' => 'bob@example.org' }]
    em.set_attribute_value('contact_points', contacts)
    df = FactoryBot.create(:data_file, extended_metadata: em)
    graph = parse_rdf(df.to_rdf)
    sub = RDF::URI(df.rdf_resource.to_s)

    blanks = graph.query([sub, RDF::URI('http://example.org/contactPoint'), nil]).map(&:object)
    assert_equal 2, blanks.size, 'Expected two contactPoint blank nodes'
    blanks.each { |b| assert b.node?, "Expected blank node, got: #{b.inspect}" }
    names = blanks.flat_map { |b| graph.query([b, RDF::URI('http://xmlns.com/foaf/0.1/name'), nil]).map { |s| s.object.to_s } }
    assert_equal %w[Alice Bob].sort, names.sort
  end

  test 'nested attribute without pid is silently skipped in rdf export' do
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_partial_pid_emt))
    em.set_attribute_value('period', { 'start_date' => '2020-01-01', 'end_date' => '2030-12-31' })
    df = FactoryBot.create(:data_file, extended_metadata: em)
    graph = parse_rdf(df.to_rdf)
    sub = RDF::URI(df.rdf_resource.to_s)

    blank = graph.query([sub, RDF::URI('http://example.org/period'), nil]).first.object
    assert_equal 1, graph.query([blank, RDF::URI('http://example.org/startDate'), nil]).to_a.size
    assert_empty graph.query([blank, RDF::URI('http://example.org/endDate'), nil]).to_a,
                 'end_date (no pid) must not appear in RDF'
  end

  test 'flat extended metadata attribute still emits plain literal triple' do
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_flat_emt))
    em.set_attribute_value('population', 'adults only')
    df = FactoryBot.create(:data_file, extended_metadata: em)
    graph = parse_rdf(df.to_rdf)
    sub = RDF::URI(df.rdf_resource.to_s)

    objects = graph.query([sub, RDF::URI('http://example.org/population'), nil]).map(&:object)
    assert_equal 1, objects.size
    assert objects.first.literal?, 'Expected a plain literal, not a blank node'
    assert_equal 'adults only', objects.first.to_s
  end

  test 'extended metadata attributes emit correctly typed XSD literals for all scalar base types' do
    em = ExtendedMetadata.new(extended_metadata_type: FactoryBot.create(:rdf_test_data_file_all_types_emt))
    em.set_attribute_value('str_field', 'hello')
    em.set_attribute_value('text_field', 'some long text')
    em.set_attribute_value('int_field', 42)
    em.set_attribute_value('float_field', 3.14)
    em.set_attribute_value('bool_field', true)
    em.set_attribute_value('date_field', '2024-06-01')
    em.set_attribute_value('datetime_field', '2024-06-01T12:00:00')
    df = FactoryBot.create(:data_file, extended_metadata: em)
    graph = parse_rdf(df.to_rdf)
    sub = RDF::URI(df.rdf_resource.to_s)

    str = graph.query([sub, RDF::URI('http://example.org/strField'), nil]).first&.object
    assert str&.literal?, 'String must emit a literal'
    assert_equal 'hello', str.to_s

    text = graph.query([sub, RDF::URI('http://example.org/textField'), nil]).first&.object
    assert text&.literal?, 'Text must emit a literal'
    assert_equal 'some long text', text.to_s

    int = graph.query([sub, RDF::URI('http://example.org/intField'), nil]).first&.object
    assert_equal RDF::XSD.integer.to_s, int.datatype.to_s, 'Integer must carry xsd:integer'
    assert_equal '42', int.to_s

    float = graph.query([sub, RDF::URI('http://example.org/floatField'), nil]).first&.object
    assert_equal RDF::XSD.double.to_s, float.datatype.to_s, 'Float must carry xsd:double'

    bool = graph.query([sub, RDF::URI('http://example.org/boolField'), nil]).first&.object
    assert_equal RDF::XSD.boolean.to_s, bool.datatype.to_s, 'Boolean must carry xsd:boolean'
    assert_equal 'true', bool.to_s

    date = graph.query([sub, RDF::URI('http://example.org/dateField'), nil]).first&.object
    assert_equal RDF::XSD.date.to_s, date.datatype.to_s, 'Date must carry xsd:date'
    assert_equal '2024-06-01', date.to_s

    dt = graph.query([sub, RDF::URI('http://example.org/datetimeField'), nil]).first&.object
    assert_equal RDF::XSD.dateTime.to_s, dt.datatype.to_s, 'DateTime must carry xsd:dateTime'
    assert_equal '2024-06-01T12:00:00', dt.to_s
  end

  private

  def parse_rdf(ttl)
    RDF::Graph.new { |g| RDF::Reader.for(:ttl).new(ttl) { |r| g << r } }
  end
end
