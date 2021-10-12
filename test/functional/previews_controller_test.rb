require 'test_helper'

class PreviewsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'can generate a preview' do
    login_as(Factory(:person))
    post :markdown, params: { content: '# Heading' }

    assert_response :success
    assert_select '.markdown-body h1', text: 'Heading'
  end

  test 'cannot generate a preview as anonymous user' do
    post :markdown, params: { content: '# Heading' }

    assert_equal 'You need to be logged in', flash[:error]
    assert_redirected_to login_path
  end
end
