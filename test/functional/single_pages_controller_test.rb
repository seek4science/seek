require 'test_helper'

class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  test 'routes' do
    assert_generates '/single_pages/1/render_sharing_form/1/type/study', controller: 'single_pages', action: 'render_sharing_form', id: 1, type: "study"
  end

end
