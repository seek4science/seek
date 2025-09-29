require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @investigation = FactoryBot.create(:investigation, contributor: @person, is_isa_json_compliant: true)
    @source_sample_type = FactoryBot.create(:isa_source_sample_type, projects: [@project], contributor: @person)
    @sample_collection_sample_type = FactoryBot.create(:isa_sample_collection_sample_type, projects: [@project], contributor: @person, linked_sample_type: @source_sample_type)
    @study = FactoryBot.create(:study, contributor: @person, investigation: @investigation, sample_types: [@source_sample_type, @sample_collection_sample_type])
    @material_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type, projects: [@project], contributor: @person, linked_sample_type: @sample_collection_sample_type)
    @assay_stream = FactoryBot.create(:assay_stream, contributor: @person, study: @study)
    @first_assay = FactoryBot.create(:assay, assay_stream: @assay_stream, study: @study, contributor: @person, sample_type: @material_assay_sample_type, position: 0)
  end

  test 'should return default dynamic table columns' do
    User.with_current_user(@person) do
      dt_def_col_name = @source_sample_type.id.to_s
      assert_equal dt_default_cols(dt_def_col_name), [{ title: 'status', name: dt_def_col_name, status: true }, { title: 'id', name: dt_def_col_name }, { title: 'uuid', name: dt_def_col_name }]
    end
  end

  test 'should return dynamic table columns' do
    dt_columns = dt_cols(@source_sample_type)
    assert_not_nil dt_columns
    assert_equal dt_columns.length, @source_sample_type.sample_attributes.length + 3 # 3 default columns
    default_column_titles = dt_default_cols(@source_sample_type.id.to_s).map { |dtdc| dtdc[:title] }
    assert dt_columns.all? { |dt_column| default_column_titles.concat(@source_sample_type.sample_attributes.map(&:title)).include? dt_column[:title] }
  end

  test'should return aggregated columns of study' do
    dt_aggregated_columns = dt_cumulative_cols(@study.sample_types)
    study_aggregated_column_names = []
    @study.sample_types.each do |type|
      study_aggregated_column_names.concat(%w[id uuid])
      study_aggregated_column_names.concat(type.sample_attributes.map(&:title))
    end

    assert_equal study_aggregated_column_names.length, dt_aggregated_columns.length
    assert dt_aggregated_columns.all? { |dt_column| study_aggregated_column_names.include? dt_column[:title] }
  end

  test 'Should return the dynamic table columns and rows' do
    User.with_current_user(@person.user) do
      # Samples
      source1 = FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person)
      source2 = FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person)
      FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person)

      sample1 = FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, contributor: @person, linked_samples: [ source1 ])
      FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, contributor: @person, linked_samples: [ source2 ])
      FactoryBot.create(:isa_material_assay_sample, sample_type: @material_assay_sample_type, contributor: @person, linked_samples: [ sample1 ])

      # Query with the Study:
      # |---------------------------------------------------------|
      # |  @source_sample_type   | @sample_collection_sample_type |
      # |------------------------|------------------------        |
      # |  (status)(id)source1   | (status)(id)sample1            |
      # |  (status)(id)source2   | (status)(id)sample2            |
      # |  (status)(id)source3   | x                              |
      # |---------------------------------------------------------|

      dt = dt_aggregated(@study)

      # Each sample types' attributes count + the sample.id
      columns_count = @study.sample_types[0].sample_attributes.length + 2
      columns_count += @study.sample_types[1].sample_attributes.length + 2

      assert_equal @source_sample_type.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      unless (dt[:rows][0].any? { |x| x == '' }) || (dt[:rows][1].any? { |x| x == '' }) || (dt[:rows][2].any? { |x| x == '' })
        puts
        puts "Flaky test debug:"
        puts
        puts dt.inspect
        puts
        pp study.sample_types
      end

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
      assert_equal false, (dt[:rows][1].any? { |x| x == '' })
      assert_equal true, (dt[:rows][2].any? { |x| x == '' })

      # Query with the Assay:
      # |------------------------------------|
      # |  @material_assay_sample_type       |
      # |------------------------------------|
      # | (status)(id)intermediate_material1 |
      # |------------------------------------|

      dt = dt_aggregated(@study, @first_assay)
      # Each sample types' attributes count + the sample.id
      columns_count = @first_assay.sample_type.sample_attributes.length + 2

      assert_equal @material_assay_sample_type.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
    end
  end

  test 'Should return the sequence of sample_type links' do
    study_sequence = link_sequence(@sample_collection_sample_type)
    assert_equal study_sequence, [@sample_collection_sample_type, @source_sample_type]

    assay_sequence = link_sequence(@material_assay_sample_type)
    assert_equal assay_sequence, [@material_assay_sample_type, @sample_collection_sample_type, @source_sample_type]
  end

  test 'should display the data correctly independent of the order in the json metadata' do
    sample_type = FactoryBot.create(:isa_source_sample_type, contributor: @person)
    sample1 = FactoryBot.create(:isa_source, sample_type:, contributor: @person)
    sample_type.reload
    rows_case1 = User.with_current_user(@person.user) do
      dt_data(sample_type)[:rows]
    end
    refute_nil rows_case1
    sample1_metadata = [[nil, sample1.id, sample1.uuid].push(*JSON.parse(sample1.json_metadata).values)]
    assert_equal sample1_metadata, rows_case1

    sample_type.sample_attributes.first.update(pos: 2)
    sample_type.sample_attributes.second.update(pos: 1)
    sample_type.reload

    rows_case2 = User.with_current_user(@person.user) do
      dt_data(sample_type)[:rows]
    end
    refute_equal rows_case2, sample1_metadata
    assert_equal sample1_metadata[0][3], rows_case2[0][4]
    assert_equal sample1_metadata[0][4], rows_case2[0][3]
  end
end
