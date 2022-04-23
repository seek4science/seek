require 'test_helper'

class PersonCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Person
  end

  def setup
    admin_login
    @person = Factory(:person)
  end

  def ignored_attributes
    super | ['email', 'skype_name', 'phone', 'web_page']
  end

  def populate_extra_attributes(hash)
    extra_attributes = {}
    if hash['data']['attributes'].key?('email')
      extra_attributes[:mbox_sha1sum] = Digest::SHA1.hexdigest("mailto:#{Addressable::URI.escape(hash['data']['attributes']['email'])}")
    end

    #by construction, expertise & tools appear together IF they appear at all
    if hash['data']['attributes'].key?('expertise_list')
      extra_attributes[:expertise] = hash['data']['attributes']['expertise_list'].split(', ')
      extra_attributes[:tools] = hash['data']['attributes']['tool_list'].split(', ')
    end

    if hash['data']['attributes'].key?('first_name') || hash['data']['attributes'].key?('last_name')
      extra_attributes[:title] = [hash['data']['attributes']['first_name'],
                                  hash['data']['attributes']['last_name']].join(' ').strip
    end

    extra_attributes.with_indifferent_access
  end

  test 'normal user cannot create person' do
    user_login(Factory(:person))
    body = api_post_body
    assert_no_difference('Person.count') do
      post "/people.json", params: body, as: :json
    end
  end

  test 'admin can update others' do
    other_person = Factory(:person)
    body = api_post_body
    body["data"]["id"] = "#{other_person.id}"
    body["data"]["attributes"]["email"] = "updateTest@email.com"
    patch "/people/#{other_person.id}.json", params: body, as: :json
    assert_response :success
  end
end
