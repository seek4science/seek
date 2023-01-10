require 'test_helper'

class ErrorsControllerTest < ActionController::TestCase
  [404, 406, 422, 500, 503].each do |code|
    test "should get error_#{code} as html" do
      get "error_#{code}".to_sym
      assert_response code
      assert_select 'h1', text: code.to_s
    end

    test "should get error_#{code} as json" do
      get "error_#{code}".to_sym, format: :json
      assert_response code
      assert_empty response.body
    end

    test "should get error_#{code} as any format" do
      get "error_#{code}".to_sym, format: :csv
      assert_response code
      assert_empty response.body
    end

    test "should get error_#{code} as javascript" do
      get "error_#{code}".to_sym, format: :js
      assert_response code
      assert_empty response.body
    end

  end
end
