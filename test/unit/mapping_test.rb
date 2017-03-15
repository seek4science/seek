require 'test_helper'

class MappingTest < ActiveSupport::TestCase
  fixtures :all

  test 'should create the association has_many compounds , through mapping_links table' do
    compound1 = Compound.new(name: 'water')
    compound2 = Compound.new(name: 'glucose')
    mapping = Mapping.new(sabiork_id: 1, chebi_id: 'CHEBI:1000', kegg_id: 'C2000')
    mapping_link1 = MappingLink.new(substance: compound1, mapping: mapping)
    mapping_link2 = MappingLink.new(substance: compound2, mapping: mapping)
    mapping.mapping_links = [mapping_link1, mapping_link2]
    assert mapping.save!
    assert_equal mapping.mapping_links.count, 2
    assert_equal mapping.mapping_links.first.substance, compound1
    assert_equal mapping.mapping_links[1].substance, compound2
  end
end
