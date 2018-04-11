require 'test_helper'
require 'time_test_helper'

class ProjectsHelperTest < ActionView::TestCase

  test 'request_project_membership_button_enabled?' do
    project_no_admins = Factory(:project)
    project_administrator = Factory(:project_administrator)
    project_with_admins = project_administrator.projects.first
    another_person = Factory(:person)


    with_config_value(:email_enabled,true) do
      User.with_current_user(project_administrator) do
        refute request_project_membership_button_enabled?(project_with_admins)  #already a member
        refute request_project_membership_button_enabled?(project_no_admins)
      end

      User.with_current_user(another_person) do
        assert request_project_membership_button_enabled?(project_with_admins)
        refute request_project_membership_button_enabled?(project_no_admins)
      end

      User.with_current_user(nil) do
        refute request_project_membership_button_enabled?(project_with_admins)
        refute request_project_membership_button_enabled?(project_no_admins)
      end
    end

    # no scenario will work without email enabled
    with_config_value(:email_enabled,false) do
      User.with_current_user(project_administrator) do
        refute request_project_membership_button_enabled?(project_with_admins)  #already a member
        refute request_project_membership_button_enabled?(project_no_admins)
      end

      User.with_current_user(another_person) do
        refute request_project_membership_button_enabled?(project_with_admins)
        refute request_project_membership_button_enabled?(project_no_admins)
      end

      User.with_current_user(nil) do
        refute request_project_membership_button_enabled?(project_with_admins)
        refute request_project_membership_button_enabled?(project_no_admins)
      end
    end

    # not if recently requested
    with_config_value(:email_enabled,true) do
      User.with_current_user(another_person) do
        pretend_now_is 16.hours.ago do
          MessageLog.create(resource:project_with_admins,sender:another_person,message_type:MessageLog::PROJECT_MEMBERSHIP_REQUEST)
        end
        assert request_project_membership_button_enabled?(project_with_admins)
        pretend_now_is 1.hour.ago do
          MessageLog.create(resource:project_with_admins,sender:another_person,message_type:MessageLog::PROJECT_MEMBERSHIP_REQUEST)
        end
        refute request_project_membership_button_enabled?(project_with_admins)
      end
    end

  end


end