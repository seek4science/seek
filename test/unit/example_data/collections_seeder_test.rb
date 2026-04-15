require 'test_helper'
class CollectionsSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @guest_person = FactoryBot.create(:person, first_name: 'Guest', last_name: 'User')
    @project = @guest_person.projects.first
    @data_file = FactoryBot.create(:data_file, contributor: @guest_person, projects: [@project])
    @model = FactoryBot.create(:model, contributor: @guest_person, projects: [@project])
    @sop = FactoryBot.create(:sop, contributor: @guest_person, projects: [@project])
    @publication = FactoryBot.create(:publication, contributor: @guest_person, projects: [@project])
  end

  def teardown
    User.current_user = nil
  end

  test 'seed collections' do
    content_hash = [
      { asset: @model, comment: 'Model related to gluconeogenesis in Sulfolobus solfataricus', order: 2 },
      { asset: @data_file, comment: 'Data file related to gluconeogenesis in Sulfolobus solfataricus', order: 1 },
      { asset: @sop, comment: 'SOP related to gluconeogenesis in Sulfolobus solfataricus', order: 3 },
      { asset: @publication, comment: 'Publication related to gluconeogenesis in Sulfolobus solfataricus', order: 4 }
    ]
    seeder = Seek::ExampleData::CollectionsSeeder.new(
      @project, @guest_person, content_hash
    )
    result = nil
    assert_difference('Collection.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :collection
      assert_not_nil result[:collection]
    end

    collection = result[:collection].reload
    assert_equal 'Gluconeogenesis in Sulfolobus solfataricus', collection.title
    assert_equal 'A collection of data files, models, SOPs and publications related to the reconstituted gluconeogenic enzyme system from Sulfolobus solfataricus.', collection.description
    assert_equal [@project], collection.projects
    assert_equal @guest_person, collection.contributor
    assert_equal 'CC-BY-4.0', collection.license
    assert_equal [], collection.creators
    assert_nil collection.other_creators
    assert_equal %w[gluconeogenesis thermophile metabolism], collection.tags
    assert_equal 4, collection.assets.count
    assert_equal [@data_file, @model, @sop, @publication], collection.items.sort_by(&:order).map(&:asset)
    comments = [
      'Data file related to gluconeogenesis in Sulfolobus solfataricus',
      'Model related to gluconeogenesis in Sulfolobus solfataricus',
      'SOP related to gluconeogenesis in Sulfolobus solfataricus',
      'Publication related to gluconeogenesis in Sulfolobus solfataricus'
    ]
    assert_equal comments, collection.items.sort_by(&:order).map(&:comment)
  end
end
