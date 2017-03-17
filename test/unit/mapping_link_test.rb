require 'test_helper'

class MappingLinkTest < ActiveSupport::TestCase
  fixtures :all

  test 'should create a mapping link' do
    mapping_link = MappingLink.new(substance: compounds(:compound_glucose), mapping: mappings(:glucose_mapping))
    assert mapping_link.save!
  end

  test 'should not create mapping link without substance or mapping' do
    mapping_link = MappingLink.new(substance: compounds(:compound_glucose))
    assert !mapping_link.save
    mapping_link = MappingLink.new(mapping: mappings(:glucose_mapping))
    assert !mapping_link.save
  end
end
