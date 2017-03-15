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
    compound = Compound.new(name: 'glucose')
    synonyms1 = Synonym.new(name: 'glc', substance: compound)
    synonyms2 = Synonym.new(name: 'glk', substance: compound)
    compound.synonyms = [synonyms1, synonyms2]
    assert compound.save!
    assert_not_nil compound.synonyms
    assert_equal compound.synonyms.count, 2
  end

  test 'should create the association compound has_many studied_factors, through studied_factor_links table ' do
    User.with_current_user users(:aaron) do
      compound = Compound.new(name: 'glucose')
      fs1 = StudiedFactor.new(data_file: data_files(:editable_data_file), data_file_version: 1, measured_item: measured_items(:concentration), unit: units(:gram), start_value: 1, end_value: 10, standard_deviation: 1)
      fs2 = StudiedFactor.new(data_file: data_files(:editable_data_file), data_file_version: 1, measured_item: measured_items(:concentration), unit: units(:gram), start_value: 1, end_value: 10, standard_deviation: 2)

      studied_factor_link1 = StudiedFactorLink.new(substance: compound, studied_factor: fs1)
      studied_factor_link2 = StudiedFactorLink.new(substance: compound, studied_factor: fs2)

      compound.studied_factor_links = [studied_factor_link1, studied_factor_link2]

      assert compound.save!
      assert_equal compound.studied_factor_links.count, 2
      assert_equal compound.studied_factor_links.first.studied_factor, fs1
      assert_equal compound.studied_factor_links[1].studied_factor, fs2
    end
  end

  test 'should create the association compound has_many experimental_conditions, through experimental_condition_links table ' do
    User.with_current_user users(:aaron) do
      compound = Compound.new(name: 'glucose')
      ec1 = ExperimentalCondition.new(sop: sops(:editable_sop), sop_version: 1, measured_item: measured_items(:concentration), unit: units(:gram), start_value: 1)
      ec2 = ExperimentalCondition.new(sop: sops(:editable_sop), sop_version: 1, measured_item: measured_items(:concentration), unit: units(:gram), start_value: 1)

      experimental_condition_link1 = ExperimentalConditionLink.new(substance: compound, experimental_condition: ec1)
      experimental_condition_link2 = ExperimentalConditionLink.new(substance: compound, experimental_condition: ec2)

      compound.experimental_condition_links = [experimental_condition_link1, experimental_condition_link2]
      assert compound.save!
      assert_equal compound.experimental_condition_links.count, 2
      assert_equal compound.experimental_condition_links.first.experimental_condition, ec1
      assert_equal compound.experimental_condition_links[1].experimental_condition, ec2
    end
  end
end
