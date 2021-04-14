require 'test_helper'

class BioSchemaTest < ActiveSupport::TestCase
  test 'supported?' do
    p = Factory(:person)
    not_supported = unsupported_type

    assert Seek::BioSchema::Serializer.supported?(p)
    refute Seek::BioSchema::Serializer.supported?(not_supported)
  end

  test 'exception for unsupported type' do
    o = unsupported_type
    assert_raise Seek::BioSchema::UnsupportedTypeException do
      Seek::BioSchema::Serializer.new(o).json_ld
    end
  end

  test 'person wrapper test' do
    p = Factory(:person, first_name: 'Bob', last_name: 'Monkhouse', description: 'I am a person', avatar: Factory(:avatar))
    refute_nil p.avatar
    wrapper = Seek::BioSchema::ResourceDecorators::Person.new(p)
    assert_equal p.id, wrapper.id
    assert_equal p.title, wrapper.title
    assert_equal p.first_name, wrapper.first_name
    assert_equal p.last_name, wrapper.last_name
    assert_equal p.description, wrapper.description
    assert_equal "http://localhost:3000/people/#{p.id}/avatars/#{p.avatar.id}?size=250", wrapper.image
  end

  test 'person json_ld' do
    p = Factory(:person, first_name: 'Bob', last_name: 'Monkhouse',
                         description: 'I am a person', avatar: Factory(:avatar),
                         web_page: 'http://me.com')
    project = p.projects.first
    refute_nil project
    refute_nil p.avatar
    json = Seek::BioSchema::Serializer.new(p).json_ld

    json = JSON.parse(json)

    assert_equal "http://localhost:3000/people/#{p.id}", json['@id']
    assert_equal 'Bob Monkhouse', json['name']
    assert_equal 'Person', json['@type']
    assert_equal 'I am a person', json['description']
    assert_equal 'Bob', json['givenName']
    assert_equal 'Monkhouse', json['familyName']
    assert_equal 'http://me.com', json['url']

    refute_nil json['image']
    refute_nil json['@context']

    member_of = json['memberOf']

    assert_equal 1, member_of.count
    expected = { '@type' => ['Project','Organization'], '@id' => project.rdf_resource, 'name' => project.title }
    assert_equal expected, member_of.first
  end

  test 'sanitize values' do
    p = Factory(:person, first_name: 'Mr <script>bob</script>', last_name: "Monk'house",
                         description: 'I am a <script>person</script>', avatar: Factory(:avatar),
                         web_page: 'http://me.com?q=fish')
    p.projects.first.update_attribute(:title, 'The <script>sane</script> project')
    json = Seek::BioSchema::Serializer.new(p).json_ld
    json = JSON.parse(json)
    assert_equal "http://localhost:3000/people/#{p.id}", json['@id']
    assert_equal "Mr bob Monk'house", json['name']
    assert_equal 'Person', json['@type']
    assert_equal 'I am a person', json['description']
    assert_equal 'Mr bob', json['givenName']
    assert_equal "Monk'house", json['familyName']
    assert_equal 'http://me.com?q=fish', json['url']

    member_of = json['memberOf']

    assert_equal 1, member_of.count
    expected = { '@type' => 'Organization', '@id' => p.projects.first.rdf_resource, 'name' => 'The sane project' }
  end

  test 'project json ld' do
    project = Factory(:project, title: 'my project', description: 'i am a project', avatar: Factory(:avatar), web_page: 'http://project.com')
    member = Factory(:person)
    member.add_to_project_and_institution(project, Factory(:institution))

    member2 = Factory(:person)
    member2.add_to_project_and_institution(project, Factory(:institution))

    refute_nil project.avatar
    json = Seek::BioSchema::Serializer.new(project).json_ld
    json = JSON.parse(json)

    assert_equal "http://localhost:3000/projects/#{project.id}", json['@id']
    assert_equal 'my project', json['name']
    assert_equal ['Project','Organization'], json['@type']
    assert_equal 'i am a project', json['description']
    assert_equal "http://localhost:3000/projects/#{project.id}/avatars/#{project.avatar.id}?size=250", json['logo']
    assert_equal 'http://project.com', json['url']
    member_json = json['member']
    refute_nil member_json
    assert_equal 2, member_json.count

    expected = { '@type' => 'Person', '@id' => member.rdf_resource, 'name' => member.title }
    assert_equal expected, member_json[0]

    expected = { '@type' => 'Person', '@id' => member2.rdf_resource, 'name' => member2.title }
    assert_equal expected, member_json[1]

    # project with no webpage, just to check the default url
    project = Factory(:project)
    json = Seek::BioSchema::Serializer.new(project).json_ld
    json = JSON.parse(json)
    assert_equal "http://localhost:3000/projects/#{project.id}", json['url']
  end

  test 'resource wrapper factory' do
    wrapper = Seek::BioSchema::ResourceDecorators::Factory.instance.get(Factory(:person))
    assert wrapper.is_a?(Seek::BioSchema::ResourceDecorators::Person)

    assert_raise Seek::BioSchema::UnsupportedTypeException do
      Seek::BioSchema::ResourceDecorators::Factory.instance.get(unsupported_type)
    end
  end

  test 'collection json_ld' do
    p = Factory(:max_collection)
    json = Seek::BioSchema::Serializer.new(p).json_ld
    json = JSON.parse(json)
    assert_equal "http://localhost:3000/collections/#{p.id}", json['@id']
    assert json['hasPart']
  end

  private

  # an instance of a model that doesn't support bio_schema / schema
  def unsupported_type
    Factory(:investigation)
  end
end
