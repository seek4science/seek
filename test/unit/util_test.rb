require 'test_helper'

class UtilTest < ActiveSupport::TestCase

  def teardown
    Seek::Util.clear_cached
  end

  test 'creatable types' do
    types = Seek::Util.user_creatable_types
    expected = [Collection, DataFile, Document, Model, Node, Presentation, Publication, Sample, Sop, Assay, Investigation, Study, Event, SampleType, Strain, Workflow]

    # first as strings for more readable failed assertion message
    assert_equal expected.map(&:to_s).sort, types.map(&:to_s).sort

    # double check they are actual types
    assert_equal expected.sort_by(&:to_s), types.sort_by(&:to_s)
  end

  test 'authorized types' do
    expected = [Assay, Collection, DataFile, Document, Event, Investigation, Model, Node, Presentation, Publication, Sample, Sop, Strain, Study, Workflow].map(&:name).sort
    actual = Seek::Util.authorized_types.map(&:name).sort
    assert_equal expected, actual
  end

  test 'rdf capable types' do
    types = Seek::Util.rdf_capable_types
    expected = %w[Assay Compound DataFile Investigation Model Organism Person Programme Project Publication Sop Strain Study]
    assert_equal expected, types.collect(&:name).sort
  end

  test 'searchable types' do
    types = Seek::Util.searchable_types
    expected = [Assay, Collection, DataFile, Document, Event, HumanDisease, Institution, Investigation, Model, Node, Organism, Person, Presentation, Programme, Project, Publication, Sample, SampleType, Sop, Strain, Study, Workflow]

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

  test 'filter out if disabled' do
    with_config_value :workflows_enabled, true do
      with_config_value :events_enabled, true do
        with_config_value :programmes_enabled, true do
          with_config_value :samples_enabled, true do
            with_config_value :publications_enabled, true do

              Seek::Util.clear_cached

              assert Seek::Util.persistent_classes.include?(Workflow)
              assert Seek::Util.authorized_types.include?(Workflow)
              assert Seek::Util.asset_types.include?(Workflow)
              assert Seek::Util.user_creatable_types.include?(Workflow)
              assert Seek::Util.searchable_types.include?(Workflow)

              assert Seek::Util.persistent_classes.include?(Node)
              assert Seek::Util.authorized_types.include?(Node)
              assert Seek::Util.asset_types.include?(Node)
              assert Seek::Util.user_creatable_types.include?(Node)
              assert Seek::Util.searchable_types.include?(Node)

              assert Seek::Util.persistent_classes.include?(Event)
              assert Seek::Util.authorized_types.include?(Event)
              assert Seek::Util.user_creatable_types.include?(Event)
              assert Seek::Util.searchable_types.include?(Event)

              assert Seek::Util.persistent_classes.include?(Sample)
              assert Seek::Util.authorized_types.include?(Sample)
              assert Seek::Util.asset_types.include?(Sample)
              assert Seek::Util.user_creatable_types.include?(Sample)
              assert Seek::Util.searchable_types.include?(Sample)

              assert Seek::Util.persistent_classes.include?(Programme)
              assert Seek::Util.searchable_types.include?(Programme)

              assert Seek::Util.persistent_classes.include?(Publication)
              assert Seek::Util.authorized_types.include?(Publication)
              assert Seek::Util.asset_types.include?(Publication)
              assert Seek::Util.user_creatable_types.include?(Publication)
              assert Seek::Util.searchable_types.include?(Publication)

              with_config_value :workflows_enabled, false do
                Seek::Util.clear_cached
                refute Seek::Util.persistent_classes.include?(Workflow)
                refute Seek::Util.authorized_types.include?(Workflow)
                refute Seek::Util.asset_types.include?(Workflow)
                refute Seek::Util.user_creatable_types.include?(Workflow)
                refute Seek::Util.searchable_types.include?(Workflow)

                refute Seek::Util.persistent_classes.include?(Node)
                refute Seek::Util.authorized_types.include?(Node)
                refute Seek::Util.asset_types.include?(Node)
                refute Seek::Util.user_creatable_types.include?(Node)
                refute Seek::Util.searchable_types.include?(Node)
              end

              with_config_value :events_enabled, false do
                Seek::Util.clear_cached
                refute Seek::Util.persistent_classes.include?(Event)
                refute Seek::Util.authorized_types.include?(Event)
                refute Seek::Util.user_creatable_types.include?(Event)
                refute Seek::Util.searchable_types.include?(Event)
              end

              with_config_value :samples_enabled, false do
                Seek::Util.clear_cached
                refute Seek::Util.persistent_classes.include?(Sample)
                refute Seek::Util.authorized_types.include?(Sample)
                refute Seek::Util.asset_types.include?(Sample)
                refute Seek::Util.user_creatable_types.include?(Sample)
                refute Seek::Util.searchable_types.include?(Sample)
              end

              with_config_value :programmes_enabled, false do
                Seek::Util.clear_cached
                refute Seek::Util.persistent_classes.include?(Programme)
                refute Seek::Util.searchable_types.include?(Programme)
              end

              with_config_value :publications_enabled, false do
                Seek::Util.clear_cached
                refute Seek::Util.persistent_classes.include?(Publication)
                refute Seek::Util.authorized_types.include?(Publication)
                refute Seek::Util.asset_types.include?(Publication)
                refute Seek::Util.user_creatable_types.include?(Publication)
                refute Seek::Util.searchable_types.include?(Publication)
              end

            end
          end
        end
      end
    end



  end
end
