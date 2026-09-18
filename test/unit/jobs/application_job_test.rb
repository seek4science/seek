require 'test_helper'

class ApplicationJobTest < ActiveSupport::TestCase
  class FollowOnTestJob < ApplicationJob
    def perform(*args); end

    def follow_on_job?
      true
    end
  end

  test 'follow on job is enqueued as a new job with its own id' do
    job = FollowOnTestJob.new('some argument')

    assert_enqueued_jobs(1, only: FollowOnTestJob) do
      job.perform_now
    end

    follow_on = enqueued_jobs.last
    assert_equal ['some argument'], follow_on['arguments']
    refute_equal job.job_id, follow_on['job_id'],
                 'the follow on job must have its own ActiveJob id, or the jobs dashboard resolves ' \
                 'every job in the chain to the last one'
  end
end
