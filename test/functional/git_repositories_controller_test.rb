require 'test_helper'

class GitRepositoriesControllerTest < ActionController::TestCase

  test 'get task status' do
    repo = FactoryBot.create(:unfetched_remote_repository)

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
    repo = FactoryBot.create(:remote_repository)

    get :refs, params: { id: repo.id, format: :json }

    res = JSON.parse(response.body)
    expected = {
      "branches" =>
        [{ "name" => "main",
           "ref" => "refs/remotes/origin/main",
           "sha" => "94ae9926a824ebe809a9e9103cbdb1d5c5f98608",
           "default" => true },
         { "name" => "add-license-1",
           "ref" => "refs/remotes/origin/add-license-1",
           "sha" => "58fe5180070ab7b5387965c5f35b8b5657096c98" },
         { "name" => "cff",
           "ref" => "refs/remotes/origin/cff",
           "sha" => "bd67097c20eade0e20d796246fbf4dbaedaf4534"
         },
         { "name" => "symlink",
           "ref" => "refs/remotes/origin/symlink",
           "sha" => "728337a507db00b8b8ba9979330a4f53d6d43b18"}],
      "tags" =>
        [{ "name" => "v0.01",
           "ref" => "refs/tags/v0.01",
           "sha" => "3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf" },
         { "name" => "v0.02",
           "ref" => "refs/tags/v0.02",
           "sha" => "94ae9926a824ebe809a9e9103cbdb1d5c5f98608" }] }

    assert_equal expected, res
  end

  test 'get refs for unfetched repository' do
    repo = FactoryBot.create(:unfetched_remote_repository)

    get :refs, params: { id: repo.id, format: :json }

    res = JSON.parse(response.body)
    expected = { "branches" => [], "tags" => [] }
    assert_equal expected, res
  end

end
