require 'test_helper'

class DecoratorTest < ActiveSupport::TestCase
  test 'Thing' do
    data_file = Factory(:data_file)
    data_file.add_annotations('red, green, blue', 'tag', User.first)
    disable_authorization_checks { data_file.save! }

    decorator = Seek::BioSchema::ResourceDecorators::Thing.new(data_file)
    identifier = "http://localhost:3000/data_files/#{data_file.id}"
    assert_equal identifier, decorator.identifier
    assert_equal identifier, decorator.url
    assert_equal 'http://schema.org', decorator.context
    assert_equal %w[blue green red], decorator.keywords.split(',').collect(&:strip).sort

    properties = decorator.attributes.collect(&:property).collect(&:to_s).sort
    assert_equal ['@id', 'description', 'keywords', 'name', 'url'], properties
  end

  test 'CreativeWork' do
    event = Factory(:event)
    document = Factory(:document, events: [event], license: 'CC-BY-4.0', creators: [Factory(:person)])
    document.add_annotations('yellow, lorry', 'tag', User.first)
    disable_authorization_checks { document.save! }

    decorator = Seek::BioSchema::ResourceDecorators::Document.new(document)
    identifier = "http://localhost:3000/documents/#{document.id}"
    assert_equal identifier, decorator.identifier
    assert_equal %w[lorry yellow], decorator.keywords.split(',').collect(&:strip).sort
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', decorator.license
    assert_equal 'application/pdf', decorator.content_type
    project = document.projects.first
    person = document.creators.first
    assert_equal [{ :@type => 'Event', :@id => "http://localhost:3000/events/#{event.id}", :name => event.title }], decorator.subject_of
    assert_equal [{ :@type => ['Project','Organization'], :@id => "http://localhost:3000/projects/#{project.id}", :name => project.title }], decorator.producer
    assert_equal [{ :@type => 'Person', :@id => "http://localhost:3000/people/#{person.id}", :name => person.title }], decorator.all_creators

    properties = decorator.attributes.collect(&:property).collect(&:to_s).sort
    assert_equal ['@id', 'creator', 'dateCreated', 'dateModified', 'description', 'encodingFormat', 'keywords', 'license', 'name', 'producer', 'subjectOf', 'url'], properties
  end
end
