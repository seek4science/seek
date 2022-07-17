require 'test_helper'

class PlaceholderApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    @creator = Factory(:person)
    @placeholder = Factory(:placeholder, policy: Factory(:public_policy), contributor: current_person, creators: [@creator])
    @file_template = Factory(:file_template)
    @data_file = Factory(:data_file)
  end

  test 'can add content to API-created placeholder' do
    skip
  end

  test 'cannot add content to API-created file template without permission' do
    skip
  end

  test 'cannot add content to API-created file template that already has content' do
    skip
  end

  test 'can create file_template with remote content' do
    skip
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
  end
end
