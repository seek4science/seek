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
        [{
           "name" => "main",
           "ref" => "refs/remotes/origin/main",
           "sha" => "94ae9926a824ebe809a9e9103cbdb1d5c5f98608",
           "time" => "2022-03-14T10:10:03.000+00:00",
           "default" => true },
         {
           "name" => "add-license-1",
           "ref" => "refs/remotes/origin/add-license-1",
           "sha" => "58fe5180070ab7b5387965c5f35b8b5657096c98",
           "time" => "2021-03-31T14:10:11.000+00:00" },
         {
           "name" => "cff",
           "ref" => "refs/remotes/origin/cff",
           "sha" => "bd67097c20eade0e20d796246fbf4dbaedaf4534",
           "time" => "2022-09-08T09:51:25.000+00:00" },
         {
           "name" => "symlink",
           "ref" => "refs/remotes/origin/symlink",
           "sha" => "728337a507db00b8b8ba9979330a4f53d6d43b18",
           "time" => "2022-06-13T14:45:22.000+00:00"
         }],
      "tags" => [
        {
          "name" => "v0.02",
          "ref" => "refs/tags/v0.02",
          "sha" => "94ae9926a824ebe809a9e9103cbdb1d5c5f98608",
          "time" => "2022-03-14T10:10:03.000+00:00" },
        {
          "name" => "v0.01",
          "ref" => "refs/tags/v0.01",
          "sha" => "3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf",
          "time" => "2021-03-31T14:09:02.000+00:00" }
      ]}

    # Turn dates back into DateTime objects (in UTC) for comparison
    # (otherwise local machine's timezone/DST may affect test result)
    ['branches', 'tags'].each do |type|
      [expected, res].each do |refs|
        refs[type].map! do |ref|
          ref['time'] = DateTime.parse(ref['time']).utc
          ref
        end
      end
    end

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
