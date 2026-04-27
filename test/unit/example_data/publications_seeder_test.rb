require 'test_helper'

class PublicationsSeederTest < ActiveSupport::TestCase
  def setup
    User.current_user = nil
    @admin_person = FactoryBot.create(:admin, first_name: 'Admin', last_name: 'Person')
    @guest_person = FactoryBot.create(:person, first_name: 'Guest', last_name: 'User')
    @project = @guest_person.projects.first
    @exp_assay = FactoryBot.create(:experimental_assay, contributor: @guest_person)
    @model_assay = FactoryBot.create(:modelling_assay, contributor: @guest_person)
    @seed_data_dir = File.join(Rails.root, 'db', 'seeds', 'example_data')
    @publication_type = PublicationType.where(key: 'journalarticle').first || FactoryBot.create(:journal)
    disable_std_output
  end

  def teardown
    enable_std_output
  end

  test 'seeded publication' do
    seeder = Seek::ExampleData::PublicationsSeeder.new(
      @project, @guest_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('Publication.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :publication
      assert_not_nil result[:publication]
    end

    pub = result[:publication].reload
    assert_equal 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
                 pub.title
    assert_match(/Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus/, pub.abstract)
    assert_equal 23_865_479, pub.pubmed_id
    assert_equal [@project], pub.projects
    assert_equal @guest_person, pub.contributor
    assert_equal 6, pub.publication_authors.size
    assert_equal @publication_type, pub.publication_type
    refute_nil pub.citation
    assert_equal Publication::REGISTRATION_BY_PUBMED, pub.registered_mode
    assert_equal %w[metabolism thermophile], pub.tags
  end

  test 'seeded presentation' do
    seeder = Seek::ExampleData::PublicationsSeeder.new(
      @project, @guest_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('Presentation.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :presentation
      assert_not_nil result[:presentation]
    end

    presentation = result[:presentation].reload
    assert_equal 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
                 presentation.title
    assert_equal 'Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system. The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of',
                 presentation.description
    assert_equal [@project], presentation.projects
    assert_equal @guest_person, presentation.contributor
    assert_equal 'presentation.pptx', presentation.content_blob.original_filename
    assert presentation.content_blob.file_exists?
    assert_equal [@guest_person], presentation.creators
  end

  test 'seeded event' do
    seeder = Seek::ExampleData::PublicationsSeeder.new(
      @project, @guest_person, @exp_assay, @model_assay, @seed_data_dir
    )
    result = nil
    assert_difference('Event.count', 1) do
      result = seeder.seed
      assert_includes result.keys, :event
      assert_not_nil result[:event]
    end

    event = result[:event].reload
    assert_equal 'Event for publication', event.title
    assert_equal 'Event for publication', event.description
    assert_equal Date.today, event.start_date
    assert_equal Date.today + 1.day, event.end_date
    assert_equal 'London', event.city
    assert_equal 'GB', event.country
    assert_equal 'Dunmore Terrace 123', event.address
    assert_equal 'http://www.seek4science.org', event.url
  end
end
