require 'test_helper'

class FacetedBrowsingHelperTest < ActionView::TestCase

  ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys

  test 'value_for_key' do
    project = Factory(:project)
    item = Factory(:data_file, :projects => [project])

    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))

    #single value
    value_for_created_date = value_for_key common_facet_config['created_at'], item
    assert_equal [item.created_at.year], value_for_created_date

    #multiple value
    project1 = Factory(:project)
    item.projects << project1
    value_for_project = value_for_key common_facet_config['project'], item
    assert_includes(value_for_project, project.title)
    assert_includes(value_for_project, project1.title)

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
        assert contributor_value.empty?
      end
    end

  end

  test 'exhibit_item_for an data_file' do
    df = Factory(:data_file)
    facet_config = YAML.load(File.read(faceted_browsing_config_path))
    facet_config_for_DF = facet_config['DataFile']
    exhibit_item = exhibit_item_for df, facet_config_for_DF

    assert_equal "#{df.class.name}#{df.id}", exhibit_item['id']
    assert_equal "#{df.class.name}#{df.id}", exhibit_item['label']
    assert_equal df.class.name, exhibit_item['type']
    assert_equal df.id, exhibit_item['item_id']
    assert_equal df.projects.collect(&:title), exhibit_item['project']
    assert_equal df.assay_type_titles, exhibit_item['assay_type']
    assert_equal df.technology_type_titles, exhibit_item['technology_type']
    assert_equal [df.created_at.year], exhibit_item['created_at']
    assert_equal df.creators.collect(&:name) + [df.contributor.person.name], exhibit_item['contributor']
    assert_equal df.tags_as_text_array, exhibit_item['tag']

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
end