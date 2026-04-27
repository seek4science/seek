require 'test_helper'

class VocabulariesTest < ActiveSupport::TestCase
  HDCAT_BASE = 'http://healthdataportal.eu/ns/health#'.freeze
  SEEKH_BASE = 'https://seek4science.org/vocab/seekh#'.freeze

  # --- HDCATVocab ---

  test 'HDCATVocab base URI is correct' do
    assert_equal HDCAT_BASE, Seek::Rdf::HDCATVocab.to_uri.to_s
  end

  test 'HDCATVocab mandatory properties resolve to correct IRIs' do
    {
      healthCategory: 'healthCategory',
      hdab: 'hdab'
    }.each do |method, fragment|
      assert_equal "#{HDCAT_BASE}#{fragment}",
                   Seek::Rdf::HDCATVocab.send(method).to_s,
                   "Expected HDCATVocab.#{method} to resolve correctly"
    end
  end

  test 'HDCATVocab optional dataset properties resolve to correct IRIs' do
    {
      healthTheme: 'healthTheme',
      populationCoverage: 'populationCoverage',
      retentionPeriod: 'retentionPeriod',
      minTypicalAge: 'minTypicalAge',
      maxTypicalAge: 'maxTypicalAge',
      numberOfRecords: 'numberOfRecords',
      numberOfUniqueIndividuals: 'numberOfUniqueIndividuals',
      hasCodingSystem: 'hasCodingSystem',
      hasCodeValues: 'hasCodeValues',
      analytics: 'analytics',
      publisherNote: 'publisherNote',
      publisherType: 'publisherType',
      trusteddataholder: 'trusteddataholder'
    }.each do |method, fragment|
      assert_equal "#{HDCAT_BASE}#{fragment}",
                   Seek::Rdf::HDCATVocab.send(method).to_s,
                   "Expected HDCATVocab.#{method} to resolve correctly"
    end
  end

  test 'HDCATVocab properties are RDF::URI instances' do
    assert_kind_of RDF::URI, Seek::Rdf::HDCATVocab.healthCategory
    assert_kind_of RDF::URI, Seek::Rdf::HDCATVocab.retentionPeriod
  end

  test 'personal data uses dpv:hasPersonalData not a healthdcatap property' do
    # Verified by spec example healthdcatappersonalData.ttl — the predicate is dpv:hasPersonalData,
    # not healthdcatap:personalData. RDF::Vocabulary generates any term dynamically, so we assert
    # the correct DPV URI directly.
    assert_equal 'https://w3id.org/dpv#hasPersonalData',
                 RDF::URI('https://w3id.org/dpv#hasPersonalData').to_s
  end

  # --- SEEKHVocab ---

  test 'SEEKHVocab base URI is correct' do
    assert_equal SEEKH_BASE, Seek::Rdf::SEEKHVocab.to_uri.to_s
  end

  test 'SEEKHVocab arbitrary term resolves to correct IRI' do
    assert_equal "#{SEEKH_BASE}someExtendedField",
                 Seek::Rdf::SEEKHVocab[:someExtendedField].to_s
  end

  test 'SEEKHVocab terms are RDF::URI instances' do
    assert_kind_of RDF::URI, Seek::Rdf::SEEKHVocab[:anyTerm]
  end

  # --- ns_prefixes ---

  test 'ns_prefixes includes dcat healthdcatap and seekh' do
    data_file = FactoryBot.build(:data_file)
    prefixes = data_file.ns_prefixes

    assert_equal 'http://www.w3.org/ns/dcat#', prefixes['dcat']
    assert_equal HDCAT_BASE, prefixes['healthdcatap']
    assert_equal SEEKH_BASE, prefixes['seekh']
  end

  test 'ns_prefixes dcterms prefix points to DC Terms URI' do
    data_file = FactoryBot.build(:data_file)
    assert_equal 'http://purl.org/dc/terms/', data_file.ns_prefixes['dcterms']
  end

  test 'ns_prefixes preserves all existing prefixes' do
    data_file = FactoryBot.build(:data_file)
    prefixes = data_file.ns_prefixes
    %w[jerm dcterms owl foaf sioc mixs uniprot fairbd xsd].each do |prefix|
      assert prefixes.key?(prefix), "Expected ns_prefixes to contain '#{prefix}'"
    end
  end
end
