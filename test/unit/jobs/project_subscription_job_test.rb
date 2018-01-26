require 'test_helper'

class ProjectSubscriptionJobTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.destroy_all
  end

  def teardown
    Delayed::Job.destroy_all
  end

  test 'exists' do
    project_subscription_id = 1
    assert !ProjectSubscriptionJob.new(project_subscription_id).exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue ProjectSubscriptionJob.new(project_subscription_id)
    end

    assert ProjectSubscriptionJob.new(project_subscription_id).exists?

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !ProjectSubscriptionJob.new(project_subscription_id).exists?, 'Should ignore locked jobs'

    job.locked_at = nil
    job.failed_at = Time.now
    job.save!
    assert !ProjectSubscriptionJob.new(project_subscription_id).exists?, 'Should ignore failed jobs'
  end

  test 'create job' do
    assert_difference('Delayed::Job.count', 1) do
      ProjectSubscriptionJob.new(1).queue_job
    end

    job = Delayed::Job.first
    assert_equal 2, job.priority

    assert_no_difference('Delayed::Job.count') do
      ProjectSubscriptionJob.new(1).queue_job
    end
  end

  test 'all_in_project' do
    project = Factory(:project)
    ps = Factory(:project_subscription, project: project)
    assets = ProjectSubscriptionJob.new(1).send(:all_in_project, project)
    assert assets.empty?

    # create items for project
    ps.subscribable_types.collect(&:name).reject { |t| t == 'Assay' || t == 'Study' }.each do |type|
      Factory("#{type.underscore.tr('/', '_')}", projects: [project])
    end
    project.reload
    # study
    study = Factory(:study, investigation: project.investigations.first)
    # assay
    Factory(:assay, study: study)

    assets = ProjectSubscriptionJob.new(1).all_in_project project
    assert_equal ps.subscribable_types.count, assets.count
  end

  test 'perform' do
    User.current_user = Factory(:user)
    proj = Factory(:project)
    s1 = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))
    s2 = Factory(:subscribable, projects: [Factory(:project), proj], policy: Factory(:public_policy))

    a_person = Factory(:person)
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    ps = a_person.project_subscriptions.create project: proj, frequency: 'weekly'

    s1.reload
    s2.reload
    assert !s1.subscribed?(a_person)
    assert !s2.subscribed?(a_person)

    # perform
    ProjectSubscriptionJob.new(ps.id).perform

    s1.reload
    s2.reload
    assert s1.subscribed?(a_person)
    assert s2.subscribed?(a_person)
  end
end
