require 'test_helper'

class FacetedBrowsingHelperTest < ActionView::TestCase
  test 'value_for_key' do
    project = Factory(:project)
    item = Factory(:data_file, :projects => [project])

    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))

    value_for_project = value_for_key common_facet_config['project'], item
    assert_equal [project.title], value_for_project

  end

  test 'generating facet search value' do
    items = []
    ASSETS_WITH_FACET = Seek::Config.facet_enable_for_pages.keys
    ASSETS_WITH_FACET.each do |type_name|
      items << Factory(type_name.singularize.to_sym)
    end

    common_facet_config = YAML.load(File.read(common_faceted_search_config_path))
    specified_facet_config = YAML.load(File.read(specified_faceted_search_config_path))

    items.each do |item|
      common_facet_config.each do |key, config_for_key|
        value_for_key config_for_key, item
      end

      facets_for_object = specified_facet_config[item.class.name] || {}

      facets_for_object.each do |key, config_for_key|
        value_for_key config_for_key, item
      end
    end
  end
end