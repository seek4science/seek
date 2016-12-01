require 'test_helper'
require 'seek/biomodels_search/search_biomodels_adaptor'

class FacetedBrowsingHelperTest < ActionView::TestCase

  ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys

  test 'value_for_key' do
    item = Factory(:data_file)
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))

    #single value
    value_for_created_date = value_for_key common_facet_config['created_at'], item
    assert_equal [item.created_at.year], value_for_created_date

    #multiple value
    project1 = Factory(:project)
    project2 = Factory(:project)
    item.projects = [project1, project2]
    value_for_project = value_for_key common_facet_config['project'], item
    assert_includes(value_for_project, project1.title)
    assert_includes(value_for_project, project2.title)

    #value through multiple associations
    value_for_contributor = value_for_key common_facet_config['contributor'], item
    assert_equal [item.contributor.person.name], value_for_contributor

    #value from multiple places
    a_person = Factory(:person)
    item.creators = [a_person]
    value_for_multiple_contributors = value_for_key common_facet_config['contributor'], item
    assert_includes(value_for_multiple_contributors, item.contributor.person.name)
    assert_includes(value_for_multiple_contributors, a_person.name)
  end

  test 'generate contributor value' do
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    ASSETS_WITH_FACET.each do |type_name|
      item = Factory(type_name.singularize.to_sym)
      contributor_value = value_for_key common_facet_config['contributor'], item
      if item.kind_of?(Assay)
        assert_equal [item.contributor.name], contributor_value
      elsif item.respond_to?(:contributor)
        assert_equal [item.contributor.person.name], contributor_value
      else
        assert_equal "(Missing value)", contributor_value
      end
    end

  end

  test 'generate contributor value for a Person object' do
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))

    a_person = Factory(:person)

    exhibit_item = exhibit_item_for a_person, common_facet_config
    assert_equal a_person.name, exhibit_item['contributor']
  end

  test 'generate project value for a Project object' do
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))

    a_project = Factory(:project)

    exhibit_item = exhibit_item_for a_project, common_facet_config
    assert_equal a_project.title, exhibit_item['project']
  end

  test 'exhibit_item_for an data_file in case of faceted browsing' do
    df = Factory(:data_file)
    facet_config = YAML.load(File.read(faceted_browsing_config_path))
    facet_config_for_DF = facet_config['DataFile']
    exhibit_item = exhibit_item_for df, facet_config_for_DF

    assert_equal "#{df.class.name}#{df.id}", exhibit_item['id']
    assert_equal "#{df.class.name}#{df.id}", exhibit_item['label']
    assert_equal df.class.name, exhibit_item['type']
    assert_equal df.id, exhibit_item['item_id']
    assert_equal df.projects.collect(&:title), exhibit_item['project']
    assert_equal "(Missing value)", exhibit_item['assay_type']
    assert_equal "(Missing value)", exhibit_item['technology_type']
    assert_equal [df.created_at.year], exhibit_item['created_at']
    assert_equal df.creators.collect(&:name) + [df.contributor.person.name], exhibit_item['contributor']
    assert_equal "(Missing value)", exhibit_item['tag']

  end

  test 'exhibit_items for all types of faceted browsing' do
    items = []
    exhibit_items = []

    ASSETS_WITH_FACET.each do |type_name|
      items << Factory(type_name.singularize.to_sym)
    end

    facet_config = YAML.load(File.read(faceted_browsing_config_path))
    items.each do |item|
      facet_config_for_item = facet_config[item.class.name] || {}
      exhibit_items << exhibit_item_for(item, facet_config_for_item)
    end

    exhibit_item_types = exhibit_items.collect{|ei| ei['type']}
    ASSETS_WITH_FACET.each do |type_name|
      klass = type_name.singularize.camelize
      assert_includes exhibit_item_types, klass
    end
  end

  test 'exhibit_item_for an data_file in case of faceted search' do
    df = Factory(:data_file)
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    specified_facet_config_for_DF = YAML.load(File.read(specified_faceted_search_config_path))['DataFile']

    exhibit_item = exhibit_item_for df, common_facet_config.merge(specified_facet_config_for_DF)

    assert_equal "#{df.class.name}#{df.id}", exhibit_item['id']
    assert_equal "#{df.class.name}#{df.id}", exhibit_item['label']
    assert_equal df.class.name, exhibit_item['type']
    assert_equal df.id, exhibit_item['item_id']
    assert_equal df.projects.collect(&:title), exhibit_item['project']
    assert_equal "(Missing value)", exhibit_item['assay_type']
    assert_equal "(Missing value)", exhibit_item['technology_type']
    assert_equal [df.created_at.year], exhibit_item['created_at']
    assert_equal df.creators.collect(&:name) + [df.contributor.person.name], exhibit_item['contributor']
    assert_equal "(Missing value)", exhibit_item['tag']

  end

  test 'exhibit_items for all types of faceted search' do
    items = []
    exhibit_items= []

    ASSETS_WITH_FACET.each do |type_name|
      items << Factory(type_name.singularize.to_sym)
    end

    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    specified_facet_config = YAML.load(File.read(specified_faceted_search_config_path))

    items.each do |item|
      facets_for_object = specified_facet_config[item.class.name] || {}
      exhibit_items << exhibit_item_for(item, common_facet_config.merge(facets_for_object))
    end

    exhibit_item_types = exhibit_items.collect{|ei| ei['type']}
    ASSETS_WITH_FACET.each do |type_name|
      klass = type_name.singularize.camelize
      assert_includes exhibit_item_types, klass
    end
  end

  test 'exhibit_tree' do
    exhibit_items = exhibit_tree 'Seek::Ontologies::AssayTypeReader', 'assay_type'
    assert_includes(exhibit_items, {'type' => 'assay_type', 'label' => 'Experimental assay type'})
    assert_includes(exhibit_items, {'type' => 'assay_type', 'label' => 'Metabolite profiling', 'subclassOf' => 'Metabolomics'})
  end

  test '-(Missing value)- for the attribute which value is not assigned' do
    df = Factory(:data_file)
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    exhibit_item = exhibit_item_for df, common_facet_config
    assert_equal '(Missing value)', exhibit_item['tag']
  end

  test "if the asset does not have this attribute, the respective value is nil" do
    df = Factory(:data_file)
    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    exhibit_item = exhibit_item_for df, common_facet_config
    assert_equal nil, exhibit_item['a_field']
  end

  test 'exhibit_item_for_external_resource: biomodel' do
    mock_service_calls
    adaptor = Seek::BiomodelsSearch::SearchBiomodelsAdaptor.new({"partial_path" => "lib/test-partial.erb", "name" => "EBI Biomodels"})
    results = adaptor.search("yeast")
    a_biomodel = results.first

    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    specified_facet_config_for_BM = YAML.load(File.read(external_faceted_search_config_path))['BioModels Database']

    exhibit_item = exhibit_item_for_external_resource a_biomodel, common_facet_config.merge(specified_facet_config_for_BM)

    assert_equal "EBI Biomodels#{a_biomodel.model_id}", exhibit_item['id']
    assert_equal "EBI Biomodels#{a_biomodel.model_id}", exhibit_item['label']
    assert_equal "EBI Biomodels", exhibit_item['type']
    assert_equal a_biomodel.model_id, exhibit_item['item_id']
    assert_equal "(Missing value)", exhibit_item['project']
    assert_equal "(Missing value)", exhibit_item['created_at']
    assert_equal "(Missing value)", exhibit_item['contributor']
    assert_equal "(Missing value)", exhibit_item['tag']
    assert_equal  [a_biomodel.published_date.to_date.year], exhibit_item['published_year']
    assert_equal a_biomodel.authors, exhibit_item['author']
  end

  private

  def mock_service_calls
    wsdl = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels.wsdl")
    stub_request(:get, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices?wsdl").to_return(wsdl)

    response = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByName"'}).
        to_return(:status=>200,:body => response)

    response2 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response2.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByChEBIId"'}).
        to_return(:status=>200,:body => response2)

    response3 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response3.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getModelsIdByPerson"'}).
        to_return(:status=>200,:body => response3)

    response4 = File.new("#{Rails.root}/test/fixtures/files/mocking/biomodels_mock_response4.xml")
    stub_request(:post, "http://www.ebi.ac.uk/biomodels-main/services/BioModelsWebServices").
        with(:headers => {'Soapaction'=>'"getSimpleModelById"'}).
        to_return(:status=>200,:body => response4.read)

    pub_response = File.new("#{Rails.root}/test/fixtures/files/mocking/pubmed_18846089.txt")
    stub_request(:post,"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi").
        to_return(:body=>pub_response)
  end
end
