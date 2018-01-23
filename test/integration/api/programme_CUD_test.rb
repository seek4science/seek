require 'test_helper'
require 'integration/api_integration_test_helper'

class ProgrammeCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = "programme"
    @plural_clz = @clz.pluralize

    load_mm_objects("programme")
    edit_relationships
  end

  #funding_codes are showed in an array upon json GET, but posted/updated as a string
  def change_funding_codes_before_CU(m)
    if !(@json_mm["#{m}"]['data']['attributes']['funding_codes'].nil?)
      @json_mm["#{m}"]['data']['attributes']['funding_codes'] = @json_mm["#{m}"]['data']['attributes']['funding_codes'].join(",")
    end
  end

  #for content comparison, need to revert back to an array, TO DO: consider changing either the input or output representations.
  def change_funding_codes_after_CU(m)
    if !(@json_mm["#{m}"]['data']['attributes']['funding_codes'].nil?)
      @json_mm["#{m}"]['data']['attributes']['funding_codes'] = @json_mm["#{m}"]['data']['attributes']['funding_codes'].split(",")
    end
  end

  def test_should_create_programme
    ['min', 'max'].each do |m|
      assert_difference('Programme.count') do
        change_funding_codes_before_CU(m)
        post "/programmes.json", @json_mm["#{m}"]
        assert_response :success

        get "/programmes/#{Programme.last.id}.json"
        assert_response :success

        change_funding_codes_after_CU(m)
        check_attr_content(@json_mm["#{m}"], "post")
      end
    end
  end

  def test_should_update_programme
    prog = Factory(:programme)
    remove_nil_values_before_update
    ['min', 'max'].each do |m|
      @json_mm["#{m}"]["data"]["id"] = "#{prog.id}"
      change_funding_codes_before_CU(m)
      patch "/programmes/#{prog.id}.json", @json_mm["#{m}"]
      assert_response :success

      get "/programmes/#{prog.id}.json"
      assert_response :success

      change_funding_codes_after_CU(m)
      check_attr_content(@json_mm["#{m}"], "patch")
    end
  end

end
