require 'test_helper'

class UtilTest < ActiveSupport::TestCase
  test 'creatable types' do
    types = Seek::Util.user_creatable_types
    expected = [DataFile, Document, Model, Node, Presentation, Publication, Sample, Sop, Assay, Investigation, Study, Event, SampleType, Strain, Workflow]

    # first as strings for more readable failed assertion message
    assert_equal expected.map(&:to_s).sort, types.map(&:to_s).sort

    # double check they are actual types
    assert_equal expected.sort_by(&:to_s), types.sort_by(&:to_s)
  end

  test 'authorized types' do
    expected = [Assay, DataFile, Document, Event, Investigation, Model, Node, Presentation, Publication, Sample, Sop, Strain, Study, Workflow].map(&:name).sort
    actual = Seek::Util.authorized_types.map(&:name).sort
    assert_equal expected, actual
  end

  test 'rdf capable types' do
    types = Seek::Util.rdf_capable_types
    expected = %w[Assay Compound CultureGrowthType DataFile Document Investigation Model Node Organism Person Programme Project Publication Sop Strain Study Workflow]
    assert_equal expected, types.collect(&:name).sort
  end

  test 'searchable types' do
    types = Seek::Util.searchable_types
    expected = ["Assay", "DataFile", "Document", "Event", "Institution", "Investigation", "Model", "Node", "Organism", "Person", "Presentation", "Programme", "Project", "Publication", "Sample", "SampleType", "Sop", "Strain", "Study", "Workflow"]

    # first as strings for more readable failed assertion message
    assert_equal expected.map(&:to_s).sort, types.map(&:to_s).sort

    # double check they are actual types
    assert_equal expected.sort_by(&:to_s), types.sort_by(&:to_s)

    with_config_value :events_enabled, false do
      Seek::Util.clear_cached
      types = Seek::Util.searchable_types
      assert_equal (expected - [Event]).map(&:to_s).sort, types.map(&:to_s).sort
    end

    with_config_value :programmes_enabled, false do
      Seek::Util.clear_cached
      types = Seek::Util.searchable_types
     assert_equal (expected - [Programme]).map(&:to_s).sort, types.map(&:to_s).sort
    end
  end

  test 'multi-file assets' do
    expected = [Model]
    types = Seek::Util.multi_files_asset_types
    # first as strings for more readable failed assertion message
    assert_equal expected.map(&:to_s).sort, types.map(&:to_s).sort

    # double check they are actual types
    assert_equal expected.sort_by(&:to_s), types.sort_by(&:to_s)
    expected.each do |type|
      assert Seek::Util.is_multi_file_asset_type?(type)
    end
  end

  test 'doiable asset types' do
    types = Seek::Util.doiable_asset_types

    expected = [DataFile, Document, Model, Sop, Investigation, Study, Assay, Node, Workflow]

    # first as strings for more readable failed assertion message
    assert_equal expected.map(&:to_s).sort, types.map(&:to_s).sort

    # double check they are actual types
    assert_equal expected.sort_by(&:to_s), types.sort_by(&:to_s)
  end
end
