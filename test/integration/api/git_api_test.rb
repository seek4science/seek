require 'test_helper'

class GitApiTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    @resource = FactoryBot.create(:ro_crate_git_workflow_with_tests)
  end

  test 'write tree example' do
    skip unless write_examples?

    user_login(@resource.contributor)
    get workflow_git_tree_path(@resource), as: :json
    assert_response :success

    write_examples(JSON.pretty_generate(JSON.parse(response.body)), 'gitTreeResponse.json')
  end

  test 'write blob example' do
    skip unless write_examples?

    user_login(@resource.contributor)
    get workflow_git_blob_path(@resource, path: 'sort-and-change-case.ga'), as: :json
    assert_response :success

    write_examples(JSON.pretty_generate(JSON.parse(response.body)), 'gitBlobResponse.json')
  end
end
