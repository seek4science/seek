require 'test_helper'
require 'integration/api_test_helper'

class PersonCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "person"
    @plural_clz = @clz.pluralize

    p = Factory(:person)
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: p.id})

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {first_name: "Post", last_name: p.last_name, email: p.email})
  end

  def create_post_values
      p = Factory(:person)
      @post_values = {first_name: "Post", last_name: p.last_name, email: "Post"+p.email}
  end

  # title cannot be POSTed or PATCHed
  # email and expertise/tool_list are not as are in the readAPI
  def ignore_non_read_or_write_attributes
    ['title', 'email', 'expertise_list', 'tool_list']
  end

  def populate_extra_attributes()
    extra_attributes = {}
    extra_attributes[:mbox_sha1sum] =  Digest::SHA1.hexdigest(URI.escape('mailto:' + @to_post['data']['attributes']['email']))
    #by construction, expertise & tools appear together IF they appear at all
    if @to_post['data']['attributes'].has_key? 'expertise_list'
      extra_attributes[:expertise] = @to_post['data']['attributes']['expertise_list'].split(', ')
      extra_attributes[:tools] =  @to_post['data']['attributes']['tool_list'].split(', ')
    end
    extra_attributes.with_indifferent_access
  end

  def test_normal_user_cannot_create_person
    user_login(Factory(:person))
    assert_no_difference('Person.count') do
      post "/people.json", @to_post
    end
  end

  def test_admin_can_update_others
    other_person = Factory(:person)
    ['min', 'max'].each do |m|
      @to_post["data"]["id"] = "#{other_person.id}"
      @to_post["data"]["attributes"]["email"] = "updateTest@email.com"
       patch "/people/#{other_person.id}.json", @to_post
       assert_response :success
    end
  end

end
