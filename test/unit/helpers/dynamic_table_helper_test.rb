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
      assert_equal dt_default_cols(dt_def_col_name), [{ title: 'status', name: dt_def_col_name, status: true, unit: {} }, { title: 'id', name: dt_def_col_name, unit: {} }, { title: 'uuid', name: dt_def_col_name, unit: {} }]
    end
  end

  test 'should return dynamic table columns' do
    dt_columns = dt_cols(@source_sample_type)
    assert_not_nil dt_columns
    assert_equal dt_columns.length, @source_sample_type.sample_attributes.length + 3 # 3 default columns
    default_column_titles = dt_default_cols(@source_sample_type.id.to_s).map { |dtdc| dtdc[:title] }
    assert dt_columns.all? { |dt_column| default_column_titles.concat(@source_sample_type.sample_attributes.map(&:title)).include? dt_column[:title] }
  end

  test 'should return aggregated columns of study' do
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

  test 'Should sanitize unauthorized samples' do
    other_person = FactoryBot.create(:person)

    # Add sources
    # Sources 1,3,5 => other_person
    # sources 2,4 => @person
    (1..5).each do |i|
      contributor = if i % 2 == 0
                      @person
                    else
                      other_person
                    end
      FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: contributor, title: "source #{i}")
    end

    User.with_current_user(other_person.user) do
      rows = dt_rows(@source_sample_type)
      assert_equal rows.length, 5

      # Even sources belong to @person, meaning two sample should have '#HIDDEN' as id.
      hidden_rows = rows.select { |r| r['id'] == '#HIDDEN' }
      assert_equal hidden_rows.length, 2
    end
  end

  test 'Should not return values of registered sample fields when unauthorized' do
    other_person = FactoryBot.create(:person)
    sources = []

    # Add sources
    # Sources 1,3,5 => other_person
    # sources 2,4 => @person
    (1..5).each do |i|
      contributor = if i % 2 == 0
                      @person
                    else
                      other_person
                    end
      sources << FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: contributor, title: "source #{i}")
    end

    # Add samples
    (1..5).each do |i|
      # source 1 => input for collected sample 1
      # ...
      # source 5 => input for collected sample 5
      linked_sample = sources[i-1]
      FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, contributor: @person, title: "collected sample #{i}", linked_samples: [linked_sample])
    end
    # Add extra sample with two inputs:
    # source 1 => Owned by other_person
    # source 2 => Owned by @person
    FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, contributor: @person, title: "collected sample with two inputs", linked_samples: [sources[0], sources[1]])

    # Input attribute = Registered Sample multi type
    input_attribute = @sample_collection_sample_type.sample_attributes.detect { |sa| sa.input_attribute? }
    refute_nil input_attribute

    User.with_current_user(@person.user) do
      rows = dt_rows(@sample_collection_sample_type)
      assert_equal rows.length, 6

      # No collected sample should be completely hidden => 'id' == '#HIDDEN'
      assert_equal rows.select { |r| r['id'] == '#HIDDEN' }.count, 0

      # Get input value
      registered_sample_values = rows.map { |r| r[input_attribute.title] }

      # 4 samples have inputs that are hidden to @person
      samples_with_hidden_inputs = registered_sample_values.select { |rsv| rsv.any? { |input| input['title'] == "#HIDDEN" } }
      assert_equal samples_with_hidden_inputs.length,4

      # last sample has one hidden input (source 1) and a visible one (source 2)
      assert_equal registered_sample_values.last.map { |input| input['title'] }, ['#HIDDEN', 'source 2']
    end

    User.with_current_user(@person.user) do
      # Delete source 4 (owned by @person)
      deleted_source = @source_sample_type.samples.detect { |sample| sample.title == 'source 4' }
      deleted_source.destroy
      @source_sample_type.reload
      assert_equal @source_sample_type.samples.length, 4

      # Deleted samples are not sanitized because the validation happens in the front end.
      # Users need to know the name of the deleted sample.
      rows = dt_rows(@sample_collection_sample_type)
      samples_with_deleted_input = rows.select { |row| row[input_attribute.title].any? { |input| input['title'] == deleted_source.title } }
      assert_equal samples_with_deleted_input.length, 1
    end
  end

  test 'Should not return values of registered data file fields when unauthorized' do
    other_person = FactoryBot.create(:person)
    data_file_attribute = FactoryBot.create(:data_file_sample_attribute, sample_type: @source_sample_type, title: 'data file', required: false, is_title: false)
    @source_sample_type.sample_attributes << data_file_attribute

    person_df = FactoryBot.create(:min_data_file, title: 'Person\'s data file.', projects: [@project], contributor: @person)
    other_person_df = FactoryBot.create(:min_data_file, title: 'Other person\'s data file', projects: [@project], contributor: other_person)

    policy = FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:manage_permission, contributor: @person), FactoryBot.create(:manage_permission, contributor: other_person)])

    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person, title: "Person\'s data file", policy: policy, data: { 'data file': person_df.id })
    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: other_person, title: "Other person\'s data file", policy: policy, data: { 'data file': other_person_df.id })

    assert_equal @source_sample_type.samples.count, 2

    # Both samples are manageable by both users
    [@person, other_person].all? { |person| @source_sample_type.samples.map { |sample| sample.can_manage?(person) } }

    # Other person's data file should be hidden to @person
    User.with_current_user(@person.user) do
      rows = dt_rows(@source_sample_type)
      hidden_df_row = rows.select { |row| row[data_file_attribute.title]['title'] == '#HIDDEN' }
      assert_equal hidden_df_row.length, 1
      assert_equal hidden_df_row.first[data_file_attribute.title]['id'], other_person_df.id
    end
  end

  test 'Should not return values of registered sop fields when unauthorized' do
    other_person = FactoryBot.create(:person)
    sop_attribute = FactoryBot.create(:sop_sample_attribute, sample_type: @source_sample_type, title: 'registered SOP', required: false, is_title: false)
    @source_sample_type.sample_attributes << sop_attribute

    person_sop = FactoryBot.create(:min_sop, title: 'Person\'s sop.', projects: [@project], contributor: @person)
    other_person_sop = FactoryBot.create(:min_sop, title: 'Other person\'s sop', projects: [@project], contributor: other_person)

    policy = FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:manage_permission, contributor: @person), FactoryBot.create(:manage_permission, contributor: other_person)])

    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person, title: "Person\'s SOP", policy: policy, data: { 'registered SOP': person_sop.id })
    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: other_person, title: "Other person\'s SOP", policy: policy, data: { 'registered SOP': other_person_sop.id })

    assert_equal @source_sample_type.samples.count, 2

    # Both samples are manageable by both users
    [@person, other_person].all? { |person| @source_sample_type.samples.map { |sample| sample.can_manage?(person) } }

    # Other person's SOP should be hidden to @person
    User.with_current_user(@person.user) do
      rows = dt_rows(@source_sample_type)
      hidden_df_row = rows.select { |row| row[sop_attribute.title]['title'] == '#HIDDEN' }
      assert_equal hidden_df_row.length, 1
      assert_equal hidden_df_row.first[sop_attribute.title]['id'], other_person_sop.id
    end
  end

  test 'Should not return values of strain fields when unauthorized' do
    other_person = FactoryBot.create(:person)
    strain_attribute = FactoryBot.create(:strain_sample_attribute, sample_type: @source_sample_type, title: 'strain used', required: false, is_title: false)
    @source_sample_type.sample_attributes << strain_attribute
    aliens = FactoryBot.create(:min_organism)
    person_strain = FactoryBot.create(:strain, organism: aliens, title: 'Person\'s strain', projects: [@project], contributor: @person, policy: FactoryBot.create(:private_policy))
    other_person_strain = FactoryBot.create(:strain, organism: aliens, title: 'Other person\'s strain', projects: [@project], contributor: other_person, policy: FactoryBot.create(:private_policy))

    policy = FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:manage_permission, contributor: @person), FactoryBot.create(:manage_permission, contributor: other_person)])

    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @person, title: "Person\'s strain", policy: policy, data: { 'strain used': person_strain.id })
    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: other_person, title: "Other person\'s strain", policy: policy, data: { 'strain used': other_person_strain.id })

    assert_equal @source_sample_type.samples.count, 2

    # Both samples are manageable by both users
    [@person, other_person].all? { |person| @source_sample_type.samples.map { |sample| sample.can_manage?(person) } }

    # Other person's SOP should be hidden to @person
    User.with_current_user(@person.user) do
      rows = dt_rows(@source_sample_type)
      hidden_df_row = rows.select { |row| row[strain_attribute.title]['title'] == '#HIDDEN' }
      assert_equal hidden_df_row.length, 1
      assert_equal hidden_df_row.first[strain_attribute.title]['id'], other_person_strain.id
    end
  end

  test 'Should return the unit if attribute has a unit' do
    ml_unit = Unit.find_by(symbol: 'mL')
    refute_nil ml_unit

    assert_difference '@material_assay_sample_type.sample_attributes.count', 1 do
      @material_assay_sample_type.sample_attributes <<  FactoryBot.create(:sample_attribute, title: 'Buffer Added', unit: ml_unit, sample_type: @source_sample_type, sample_attribute_type: FactoryBot.create(:float_sample_attribute_type))
    end
    User.with_current_user(@person.user) do
      # Test the dynamic table
      cols = dt_cols(@material_assay_sample_type)
      columns_with_unit = cols.select { |col| col[:unit][:symbol] == ml_unit&.symbol }
      assert_equal columns_with_unit.count, 1

      # Test the cumulative (Read-Only) table
      ro_cols = dt_cumulative_cols([@material_assay_sample_type])
      ro_cols_with_unit = ro_cols.select { |col| col[:unit][:symbol] == ml_unit&.symbol }
      assert_equal ro_cols_with_unit.count, 1
    end
  end
end
