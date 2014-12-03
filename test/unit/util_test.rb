require 'test_helper'

class UtilTest < ActiveSupport::TestCase
  test 'creatable types' do
    types = Seek::Util.user_creatable_types
    expected = [DataFile, Model, Presentation, Publication, Sop, Workflow, Assay, Investigation, Study, Event, Sample, Specimen, Strain]

    # first as strings for more readable failed assertion message
    assert_equal expected.map { |t| t.to_s }, types.map { |t| t.to_s }

    # double check they are actual types
    assert_equal expected, types
  end

  test 'authorized types' do
    expected =  [Assay, DataFile, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Specimen, Strain, Study, Sweep, TavernaPlayer::Run, Workflow].map(&:name)
    actual = Seek::Util.authorized_types.map(&:name)
    assert_equal expected, actual
  end

  test 'rdf capable types' do
    types = Seek::Util.rdf_capable_types
    assert types.include?(DataFile)
    assert !types.include?(Policy)
  end

  test 'searchable types' do
    types = Seek::Util.searchable_types
    expected = [Assay, DataFile, Event, Institution, Investigation, Model, Person, Presentation, Programme, Project, Publication, Sample, Sop, Specimen, Strain, Study, Workflow]

    # first as strings for more readable failed assertion message
    assert_equal expected.map { |t| t.to_s }, types.map { |t| t.to_s }

    # double check they are actual types
    assert_equal expected, types
  end

  test "doiable asset types" do
    types = Seek::Util.doiable_asset_types

    expected = [DataFile, Model, Sop, Workflow]

    # first as strings for more readable failed assertion message
    assert_equal expected.map { |t| t.to_s }, types.map { |t| t.to_s }

    # double check they are actual types
    assert_equal expected, types
  end
end
