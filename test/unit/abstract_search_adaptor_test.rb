require 'test_helper'

class AbstractSearchAdaptorTest < ActiveSupport::TestCase
  test 'abstract adaptor' do
    adaptor = Seek::AbstractSearchAdaptor.new('partial_path' => 'lib/test-partial.erb')
    assert_raise(NoMethodError) do
      adaptor.search('yeast')
    end
  end

  test 'reading base config' do
    adaptor = Seek::AbstractSearchAdaptor.new('enabled' => true, 'partial_path' => 'lib/a-path.erb', 'name' => 'NATure Protocols', 'search_type' => 'sops')

    assert adaptor.enabled?
    assert_equal 'lib/a-path.erb', adaptor.partial_path
    assert_equal 'NATure Protocols', adaptor.name
    assert_equal 'sops', adaptor.search_type

    adaptor = Seek::AbstractSearchAdaptor.new('enabled' => false, 'partial_path' => 'lib/a-path.erb')
    assert !adaptor.enabled?
  end

  test 'reading from yaml file' do
    yaml = YAML.load_file("#{Rails.root}/test/fixtures/files/search_adaptor_config")
    adaptor = Seek::AbstractSearchAdaptor.new(yaml)
    assert !adaptor.enabled?
    assert_equal 'lib/seek/biomodels_search/_biomodels_resource_list_item.html.erb', adaptor.partial_path
    assert_equal 'BioModels Database', adaptor.name
    assert_equal 'models', adaptor.search_type
  end
end
