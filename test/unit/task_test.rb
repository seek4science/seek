require 'test_helper'
require 'minitest/mock'

class TaskTest < ActiveSupport::TestCase
  setup do
    stub_request(:head, 'http://www.abc.com').to_return(
        headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com').to_return(body: 'abcdefghij' * 10,
                                                       headers: { content_type: 'text/plain' }, status: 200)

    @content_blob = FactoryBot.create(:url_content_blob)
  end

  test 'initialize task' do
    assert @content_blob.tasks.empty?

    assert @content_blob.remote_content_fetch_task
    refute @content_blob.remote_content_fetch_task.persisted?
  end

  test 'get existing task' do
    task = @content_blob.remote_content_fetch_task
    task.start
    assert task.save

    refute @content_blob.tasks.empty?
    assert_equal task, @content_blob.remote_content_fetch_task
    assert @content_blob.remote_content_fetch_task.persisted?
  end

  test 'new task status is nil' do
    assert_nil @content_blob.remote_content_fetch_task.status

    refute @content_blob.remote_content_fetch_task.pending?
    refute @content_blob.remote_content_fetch_task.in_progress?
    refute @content_blob.remote_content_fetch_task.completed?
    refute @content_blob.remote_content_fetch_task.cancelled?
  end

  test 'started task status is waiting' do
    @content_blob.remote_content_fetch_task.start
    assert_equal Task::STATUS_WAITING, @content_blob.remote_content_fetch_task.status

    assert @content_blob.remote_content_fetch_task.pending?
    refute @content_blob.remote_content_fetch_task.in_progress?
    refute @content_blob.remote_content_fetch_task.completed?
    refute @content_blob.remote_content_fetch_task.cancelled?
  end

  test 'queued task status is queued' do
    RemoteContentFetchingJob.perform_later(@content_blob)
    assert_equal Task::STATUS_QUEUED, @content_blob.remote_content_fetch_task.status

    assert @content_blob.remote_content_fetch_task.pending?
    assert @content_blob.remote_content_fetch_task.in_progress?
    refute @content_blob.remote_content_fetch_task.completed?
    refute @content_blob.remote_content_fetch_task.cancelled?
  end

  test 'errored task status is failed' do
    @content_blob.stub(:retrieve, -> { raise 'error' }) do
      RemoteContentFetchingJob.perform_now(@content_blob)
      assert_equal Task::STATUS_FAILED, @content_blob.remote_content_fetch_task.status
      assert_nil @content_blob.reload.file_size

      refute @content_blob.remote_content_fetch_task.pending?
      refute @content_blob.remote_content_fetch_task.in_progress?
      assert @content_blob.remote_content_fetch_task.completed?
      refute @content_blob.remote_content_fetch_task.cancelled?
    end
  end

  test 'done task status is done' do
    RemoteContentFetchingJob.perform_now(@content_blob)
    assert_equal Task::STATUS_DONE, @content_blob.remote_content_fetch_task.status
    assert_equal 100, @content_blob.file_size

    refute @content_blob.remote_content_fetch_task.pending?
    refute @content_blob.remote_content_fetch_task.in_progress?
    assert @content_blob.remote_content_fetch_task.completed?
    refute @content_blob.remote_content_fetch_task.cancelled?
  end

  test 'stop job execution if task is cancelled' do
    skip 'No good way to test this until Rails 6.1, because enqueueing and performing jobs happens in one step when testing'
    RemoteContentFetchingJob.perform_later(@content_blob)

    # Delete the task then run the job

    assert_equal Task::STATUS_CANCELLED, @content_blob.remote_content_fetch_task.status
    assert_nil @content_blob.file_size

    refute @content_blob.remote_content_fetch_task.pending?
    refute @content_blob.remote_content_fetch_task.in_progress?
    refute @content_blob.remote_content_fetch_task.completed?
    assert @content_blob.remote_content_fetch_task.cancelled?
  end
end
