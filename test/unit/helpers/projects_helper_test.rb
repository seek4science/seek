require 'test_helper'

class ProjectsHelperTest < ActionView::TestCase

  test 'request_project_membership_button_enabled?' do
    project_no_admins = FactoryBot.create(:project)
    project_administrator = FactoryBot.create(:project_administrator)
    project_with_admins = project_administrator.projects.first
    another_person = FactoryBot.create(:person)


    with_config_value(:email_enabled,true) do
      User.with_current_user(project_administrator) do
        refute request_join_project_button_enabled?(project_with_admins)  #already a member
        refute request_join_project_button_enabled?(project_no_admins)
      end

      User.with_current_user(another_person) do
        assert request_join_project_button_enabled?(project_with_admins)
        refute request_join_project_button_enabled?(project_no_admins)
      end

      User.with_current_user(nil) do
        refute request_join_project_button_enabled?(project_with_admins)
        refute request_join_project_button_enabled?(project_no_admins)
      end
    end

    # updated to work without email enabled
    with_config_value(:email_enabled,false) do
      User.with_current_user(project_administrator) do
        refute request_join_project_button_enabled?(project_with_admins)  #already a member
        refute request_join_project_button_enabled?(project_no_admins)
      end

      User.with_current_user(another_person) do
        assert request_join_project_button_enabled?(project_with_admins)
        refute request_join_project_button_enabled?(project_no_admins)
      end

      User.with_current_user(nil) do
        refute request_join_project_button_enabled?(project_with_admins)
        refute request_join_project_button_enabled?(project_no_admins)
      end
    end

    # not if recently requested
    with_config_value(:email_enabled,true) do
      User.with_current_user(another_person) do
        travel_to 16.hours.ago do
          ProjectMembershipMessageLog.create(subject:project_with_admins,sender:another_person)
        end
        assert request_join_project_button_enabled?(project_with_admins)
        travel_to 1.hour.ago do
          ProjectMembershipMessageLog.create(subject:project_with_admins,sender:another_person)
        end
        refute request_join_project_button_enabled?(project_with_admins)
      end
    end

  end


end