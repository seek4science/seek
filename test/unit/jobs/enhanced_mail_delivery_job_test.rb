require 'test_helper'
require 'minitest/mock'

class EnhancedMailDeliveryJobTest < ActiveSupport::TestCase
  test 'perform' do
    with_config_value(:email_enabled, true) do

      assert_enqueued_jobs(1, only: EnhancedMailDeliveryJob, queue: QueueNames::MAILERS) do
        Mailer.test_email('fred@email.com').deliver_later
      end

      smtp_propagate_called = false
      site_base_host_propagate_called = false

      Seek::Config.stub :smtp_propagate, ->{smtp_propagate_called = true} do
        Seek::Config.stub :site_base_host_propagate, ->{site_base_host_propagate_called = true} do
          assert_emails 1 do
            assert_performed_jobs(1, only: EnhancedMailDeliveryJob) do
              Mailer.test_email('fred@email.com').deliver_later
            end
          end
        end
      end

      assert smtp_propagate_called
      assert site_base_host_propagate_called
    end
  end
end