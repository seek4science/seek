require 'test_helper'

class DecoratorTest < ActiveSupport::TestCase
  test 'Thing' do
    data_file = FactoryBot.create(:data_file)
    data_file.add_annotations('red, green, blue', 'tag', User.first)
    disable_authorization_checks { data_file.save! }

    decorator = Seek::BioSchema::ResourceDecorators::Thing.new(data_file)
    identifier = "http://localhost:3000/data_files/#{data_file.id}"
    assert_equal identifier, decorator.identifier
    assert_equal identifier, decorator.url
    assert_equal Seek::BioSchema::Serializer::SCHEMA_ORG, decorator.context
    assert_equal %w[blue green red], decorator.keywords.split(',').collect(&:strip).sort

    properties = decorator.attributes.collect(&:property).collect(&:to_s).sort
    assert_equal ['@id', 'description', 'image', 'keywords', 'name', 'url'], properties
  end

  test 'CreativeWork' do
    event = FactoryBot.create(:event, policy: FactoryBot.create(:public_policy))
    publication = FactoryBot.create(:publication, policy: FactoryBot.create(:public_policy))
    document = FactoryBot.create(:document, events: [event],
                                            license: 'CC-BY-4.0', creators: [FactoryBot.create(:person)],
                                            doi: '10.10.10.10/test.1', publications: [publication])
    document.add_annotations('yellow, lorry', 'tag', User.first)
    disable_authorization_checks { document.save! }
    doi_log = travel_to(Time.now + 1.day) do
      AssetDoiLog.create!(asset: document, doi: '10.10.10.10/test.1', asset_version: document.version,
                          action: AssetDoiLog::MINT, user: document.contributor.user)
    end
    document.latest_version.update_column(:doi, '10.10.10.10/test.1')

    decorator = Seek::BioSchema::ResourceDecorators::Document.new(document)
    identifier = "http://localhost:3000/documents/#{document.id}"
    assert_equal identifier, decorator.identifier
    assert_equal %w[lorry yellow], decorator.keywords.split(',').collect(&:strip).sort
    assert_equal 'https://spdx.org/licenses/CC-BY-4.0', decorator.license
    assert_equal 'application/pdf', decorator.content_type
    assert_equal 'https://doi.org/10.10.10.10/test.1', decorator.doi
    project = document.projects.first
    person = document.creators.first
    assert_equal [{ :@type => 'Event', :@id => "http://localhost:3000/events/#{event.id}", :name => event.title }], decorator.subject_of
    assert_equal [{ :@type => ['Project','Organization'], :@id => "http://localhost:3000/projects/#{project.id}", :name => project.title }], decorator.producer
    assert_equal [{ :@type => 'Person', :@id => "http://localhost:3000/people/#{person.id}", :name => person.title }], decorator.all_creators
    assert_equal doi_log.created_at.iso8601, decorator.date_published
    assert_equal [ { '@type' => 'ScholarlyArticle', '@id' => "http://localhost:3000/publications/#{publication.id}", 'name' => publication.title } ],
                      decorator.publications
    

    properties = decorator.attributes.collect(&:property).collect(&:to_s).sort
    assert_equal %w[@id citation creator dateCreated dateModified datePublished description encodingFormat identifier image isBasedOn isPartOf keywords license name producer subjectOf url version], properties
  end

  test 'Dataset pads or truncates description' do
    df = FactoryBot.create(:data_file, description:'')
    assert_equal 'Description not specified.........................', Seek::BioSchema::ResourceDecorators::DataFile.new(df).description
    df = FactoryBot.create(:data_file, description:'fish')
    assert_equal 'fish..............................................', Seek::BioSchema::ResourceDecorators::DataFile.new(df).description
    df = FactoryBot.create(:data_file, description:'m'*100)
    assert_equal 'm'*100, Seek::BioSchema::ResourceDecorators::DataFile.new(df).description
    df = FactoryBot.create(:data_file, description:'m'*10000)
    assert_equal 4999, Seek::BioSchema::ResourceDecorators::DataFile.new(df).description.length
    assert_equal 'm'*4996 + '...', Seek::BioSchema::ResourceDecorators::DataFile.new(df).description
  end
end
