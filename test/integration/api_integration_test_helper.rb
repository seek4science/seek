module ApiIntegrationTestHelper
  include AuthenticatedTestHelper

  def admin_login
    admin_user = Factory(:admin).user
    admin_user.password = "blah"
    post '/session', login: admin_user.login, password: admin_user.password
  end

  def load_mm_objects(clz)
    @json_mm = {}
    ['min', 'max'].each do |m|
      json_mm_file = File.join(Rails.root, 'test', 'fixtures', 'files', 'json', 'content_compare', "#{m}_#{clz}.json")
      @json_mm["#{m}"] = JSON.parse(File.read(json_mm_file))
      #TO DO may need to separate that later
      @json_mm["#{m}"]["data"].delete("id")
    end
  end

  def remove_nil_values_before_update
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["attributes"].each do |k, v|
        @json_mm["#{m}"]["data"]["attributes"].delete k if @json_mm["#{m}"]["data"]["attributes"][k].nil?
      end
    end
  end

  def check_attr_content(to_post, action)
    #check some of the content, h = the response hash after the post/patch action
    h = JSON.parse(response.body)
    h['data']['attributes'].delete("mbox_sha1sum")
    h['data']['attributes'].delete("avatar")
    h['data']['attributes'].each do |key, value|
      next if (to_post['data']['attributes'][key].nil? && action=="patch")
      if value.nil?
        assert_nil to_post['data']['attributes'][key]
      elsif value.kind_of?(Array)
        assert_equal value, to_post['data']['attributes'][key].sort!
      else
        assert_equal value, to_post['data']['attributes'][key]
      end
    end
  end

  # def check_relationships_content(m, action)
  #   @to_post['data']['relationships'].each do |key, value|
  #     assert_equal value, h['data']['relationships'][key]
  #   end
  # end

  def test_create_should_error_on_given_id
    @json_mm["min"]["data"]["id"] = "100000000"
    @json_mm["min"]["data"]["type"] = "#{@plural_clz}"
    post "/#{@plural_clz}.json", @json_mm["min"]
    assert_response :unprocessable_entity
    assert_match "A POST request is not allowed to specify an id", response.body
  end

end
