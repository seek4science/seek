require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper
  test 'Should return the dynamic table columns and rows' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    User.with_current_user(person.user) do
      inv = FactoryBot.create(:investigation, projects: [project], contributor: person, is_isa_json_compliant: true)

      # Sample types
      source_sample_type = FactoryBot.create(:isa_source_sample_type, projects: [project], contributor: person)
      sample_collection_sample_type = FactoryBot.create(:isa_sample_collection_sample_type, projects: [project], contributor: person, linked_sample_type: source_sample_type)
      material_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type, projects: [project], contributor: person, linked_sample_type: sample_collection_sample_type)

      # Samples
      source1 = FactoryBot.create(:isa_source, sample_type: source_sample_type, contributor: person)
      source2 = FactoryBot.create(:isa_source, sample_type: source_sample_type, contributor: person)
      source3 = FactoryBot.create(:isa_source, sample_type: source_sample_type, contributor: person)

      sample1 = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, contributor: person, linked_samples: [ source1 ])
      sample2 = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, contributor: person, linked_samples: [ source2 ])

      intermediate_material1 = FactoryBot.create(:isa_material_assay_sample, sample_type: material_assay_sample_type, contributor: person, linked_samples: [ sample1 ])

      # ISA
      study = FactoryBot.create(:study, investigation: inv, contributor: person, sample_types: [source_sample_type, sample_collection_sample_type])
      assay_stream = FactoryBot.create(:assay_stream, contributor: person, study: )
      assay = FactoryBot.create(:assay, study: , contributor: person, sample_type: material_assay_sample_type, position: 0)

      # Query with the Study:
      # |---------------------------------------------------------|
      # |  source_sample_type    |  sample_collection_sample_type |
      # |------------------------|------------------------        |
      # |  (status)(id)source1   | (status)(id)sample1            |
      # |  (status)(id)source2   | (status)(id)sample2            |
      # |  (status)(id)source3   | x                              |
      # |---------------------------------------------------------|

      dt = dt_aggregated(study)

      # Each sample types' attributes count + the sample.id
      columns_count = study.sample_types[0].sample_attributes.length + 2
      columns_count += study.sample_types[1].sample_attributes.length + 2

      assert_equal source_sample_type.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
      assert_equal false, (dt[:rows][1].any? { |x| x == '' })
      assert_equal true, (dt[:rows][2].any? { |x| x == '' })

      # Query with the Assay:
      # |------------------------------------|
      # |  material_assay_sample_type        |
      # |------------------------------------|
      # | (status)(id)intermediate_material1 |
      # |------------------------------------|

      dt = dt_aggregated(study, assay)
      # Each sample types' attributes count + the sample.id
      columns_count = assay.sample_type.sample_attributes.length + 2

      assert_equal material_assay_sample_type.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
    end
  end

  test 'Should return the sequence of sample_type links' do
    type1 = FactoryBot.create(:isa_source_sample_type)
    type2 = FactoryBot.create(:isa_sample_collection_sample_type, linked_sample_type: type1)
    type3 = FactoryBot.create(:isa_assay_material_sample_type, linked_sample_type: type2)

    sequence = link_sequence(type3)
    assert_equal sequence, [type3, type2, type1]
  end

  test 'should display the data correctly independent of the order in the json metadata' do
    person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:isa_source_sample_type, contributor: person)
    sample1 = FactoryBot.create(:isa_source, sample_type:, contributor: person)
    sample_type.reload
    rows_case1 = User.with_current_user(person.user) do
      dt_data(sample_type)[:rows]
    end
    refute_nil rows_case1
    sample1_metadata = [[nil, sample1.id, sample1.uuid].push(*JSON.parse(sample1.json_metadata).values)]
    assert_equal sample1_metadata, rows_case1

    sample_type.sample_attributes.first.update(pos: 2)
    sample_type.sample_attributes.second.update(pos: 1)
    sample_type.reload

    rows_case2 = User.with_current_user(person.user) do
      dt_data(sample_type)[:rows]
    end
    refute_equal rows_case2, sample1_metadata
    assert_equal sample1_metadata[0][3], rows_case2[0][4]
    assert_equal sample1_metadata[0][4], rows_case2[0][3]
  end
end
