require 'test_helper'

class SendImmediateEmailsJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
  end

  def teardown
    Seek::Config.email_enabled = @val
  end

  test 'perform' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    project_subscription1 = ProjectSubscription.create(person_id: person1.id, project_id: sop.projects.first.id, frequency: 'immediately')
    project_subscription2 = ProjectSubscription.create(person_id: person2.id, project_id: sop.projects.first.id, frequency: 'immediately')
    ProjectSubscriptionJob.perform_now(project_subscription1)
    ProjectSubscriptionJob.perform_now(project_subscription2)
    assert_enqueued_emails 2 do
      disable_authorization_checks do
        al = ActivityLog.create(activity_loggable: sop, culprit: FactoryBot.create(:user), action: 'create')
        ImmediateSubscriptionEmailJob.perform_now(al)
      end
    end
  end
end
