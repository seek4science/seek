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

  test 'should add nofollow to markdown links' do
    login_as(Factory(:person))
    post :markdown, params: { content: "[Link1](https://example.com) https://example.com [Link3](https://example.com \"Blablabla\")" }

    assert_response :success
    assert_select '.markdown-body a[rel="nofollow"]', count: 3
  end

  test 'HTML tag filtering' do
    login_as(Factory(:person))

    desc = 'This is <b>Bold</b> - this is <em>emphasised</em> - this is super<sup>script</sup> - '
    desc << 'this is link to google: http://google.com - '
    desc << "this is some nasty javascript <script>alert('fred');</script>"
    post :markdown, params: { content: desc }

    assert_response :success
    assert_select '.markdown-body b', count: 1
    assert_select '.markdown-body em', count: 1
    assert_select '.markdown-body sup', count: 1
    assert_select '.markdown-body script', count: 0
  end
end
