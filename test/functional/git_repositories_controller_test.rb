require 'test_helper'

class GitRepositoriesControllerTest < ActionController::TestCase

  test 'get task status' do
    repo = Factory(:unfetched_remote_repository)

    assert_difference('Task.count', 1) do
      repo.queue_fetch
    end

    get :status, params: { id: repo.id, format: :json }

    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 'queued', res['status']
    assert_equal 'Queued', res['text']

    repo.remote_git_fetch_task.update_attribute(:status, Task::STATUS_DONE)

    get :status, params: { id: repo.id, format: :json }

    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 'done', res['status']
    assert_equal 'Done', res['text']
  end

  test 'get refs' do
    repo = Factory(:remote_repository)

    get :refs, params: { id: repo.id, format: :json }

    res = JSON.parse(response.body)
    expected = {
      "branches" =>
        [{ "name" => "main",
           "ref" => "refs/remotes/origin/main",
           "sha" => "b6312caabe582d156dd351fab98ce78356c4b74c",
           "default" => true },
         { "name" => "add-license-1",
           "ref" => "refs/remotes/origin/add-license-1",
           "sha" => "58fe5180070ab7b5387965c5f35b8b5657096c98" }],
      "tags" =>
        [{ "name" => "v0.01",
           "ref" => "refs/tags/v0.01",
           "sha" => "3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf" }] }

    assert_equal expected, res
  end

  test 'get refs for unfetched repository' do
    repo = Factory(:unfetched_remote_repository)

    get :refs, params: { id: repo.id, format: :json }

    res = JSON.parse(response.body)
    expected = { "branches" => [], "tags" => [] }
    assert_equal expected, res
  end

end
