require 'test_helper'

class CompoundTest < ActiveSupport::TestCase
  fixtures :all
  test 'should create compound with the name' do
    compound = Compound.new(name: 'water')
    assert compound.save!
  end

  test 'to rdf' do
    compound = Factory :compound
    mapping1 = Mapping.new(sabiork_id: 1, chebi_id: '1000', kegg_id: 'C2000')
    mapping2 = Mapping.new(sabiork_id: 2, chebi_id: '1001', kegg_id: 'C2001')
    mapping_link1 = MappingLink.new(substance: compound, mapping: mapping1)
    mapping_link2 = MappingLink.new(substance: compound, mapping: mapping2)
    compound.mapping_links = [mapping_link1, mapping_link2]
    compound.reload
    rdf = compound.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/compounds/#{compound.id}"), reader.statements.first.subject
    end
  end

  test 'chebi ids and sabiork_ids' do
    compound = Factory(:compound)
    mapping1 = Mapping.new(sabiork_id: 1, chebi_id: 'CHEBI:1000', kegg_id: 'C2000')
    mapping2 = Mapping.new(sabiork_id: 2, chebi_id: 'CHEBI:1001', kegg_id: 'C2001')
    mapping_link1 = MappingLink.new(substance: compound, mapping: mapping1)
    mapping_link2 = MappingLink.new(substance: compound, mapping: mapping2)
    compound.mapping_links = [mapping_link1, mapping_link2]
    compound.reload
    assert_equal 2, compound.mapping_links.size
    assert_equal ['CHEBI:1000', 'CHEBI:1001'], compound.chebi_ids.sort
    assert_equal [1, 2], compound.sabiork_ids.sort
  end

  test 'should create the association compound has_many mappings, through mapping_links table' do
    compound = Compound.new(name: 'water')

    mapping1 = Mapping.new(sabiork_id: 1, chebi_id: 'CHEBI:1000', kegg_id: 'C2000')
    mapping2 = Mapping.new(sabiork_id: 1, chebi_id: 'CHEBI:1000', kegg_id: 'C2001')
    mapping_link1 = MappingLink.new(substance: compound, mapping: mapping1)
    mapping_link2 = MappingLink.new(substance: compound, mapping: mapping2)
    compound.mapping_links = [mapping_link1, mapping_link2]

    assert compound.save!
    assert_equal compound.mapping_links.count, 2
    assert_equal compound.mapping_links.first.mapping, mapping1
    assert_equal compound.mapping_links[1].mapping, mapping2
  end

  test 'should create the association has_many with synonyms table' do
    compound = Compound.new(name: 'Fructose')
    synonyms1 = Synonym.new(name: 'glc', substance: compound)
    synonyms2 = Synonym.new(name: 'glk', substance: compound)
    compound.synonyms = [synonyms1, synonyms2]
    assert compound.save!
    assert_not_nil compound.synonyms
    assert_equal compound.synonyms.count, 2
  end

end
