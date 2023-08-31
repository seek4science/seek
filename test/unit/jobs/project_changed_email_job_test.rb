require 'test_helper'

class ProjectChangedEmailJobTest < ActiveSupport::TestCase
  test 'perform' do
    with_config_value(:email_enabled, true) do
      project = FactoryBot.create(:project)
      assert_enqueued_emails(1) do
        ProjectChangedEmailJob.perform_now(project)
      end
    end
  end
end
