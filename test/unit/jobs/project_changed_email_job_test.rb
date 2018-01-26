require 'test_helper'

class ProjectChangedEmailJobTest < ActiveSupport::TestCase
  test 'exists?' do
    project = Factory(:project)
    refute ProjectChangedEmailJob.new(project).exists?

    Delayed::Job.enqueue ProjectChangedEmailJob.new(project)

    assert ProjectChangedEmailJob.new(project).exists?
  end

  test 'create job' do
    project = Factory(:project)

    Delayed::Job.delete_all

    assert_difference('Delayed::Job.count', 1) do
      ProjectChangedEmailJob.new(project).queue_job
    end
    job = Delayed::Job.last
    assert_equal 2, job.priority

    # wont create duplicate
    assert_no_difference('Delayed::Job.count') do
      ProjectChangedEmailJob.new(project).queue_job
    end

    # will create for new project
    new_project = Factory(:project)
    assert_difference('Delayed::Job.count', 1) do
      ProjectChangedEmailJob.new(new_project).queue_job
    end
  end

  test 'perform' do
    project = Factory(:project)
    job = ProjectChangedEmailJob.new(project)
    assert_emails(1) do
      job.perform
    end
  end
end
