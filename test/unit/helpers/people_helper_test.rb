require 'test_helper'

class PeopleHelperTest < ActionView::TestCase

  # mocking the methods that are added as helper methods via AuthenticatedSystem when included in ApplicationController (using helper_method :xxx)
  PeopleHelperTest.class_eval do
    define_method :logged_in? do
      User.logged_in?
    end
    define_method :current_user do
      User.current_user
    end
  end

  test'hide_contact_details?' do
    PeopleController.new
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)
    project = person.projects.first
    person_same_project = FactoryBot.create(:person)
    person_same_project.add_to_project_and_institution(project, person.institutions.first)
    person_different_project = FactoryBot.create(:person)
    different_project = person_different_project.projects.first

    User.with_current_user(person.user) do
      with_config_value(:hide_details_enabled, false) do
        refute hide_contact_details?(person_same_project)
        assert hide_contact_details?(person_different_project)
        refute hide_contact_details?(project)
        assert hide_contact_details?(different_project)
      end

      with_config_value(:hide_details_enabled, true) do
        assert hide_contact_details?(person_same_project)
        assert hide_contact_details?(person_different_project)
        assert hide_contact_details?(project)
        assert hide_contact_details?(different_project)
      end
    end

    User.with_current_user(nil) do
      with_config_value(:hide_details_enabled, false) do
        assert hide_contact_details?(person_same_project)
        assert hide_contact_details?(person_different_project)
        assert hide_contact_details?(project)
        assert hide_contact_details?(different_project)
      end

      with_config_value(:hide_details_enabled, true) do
        assert hide_contact_details?(person_same_project)
        assert hide_contact_details?(person_different_project)
        assert hide_contact_details?(project)
        assert hide_contact_details?(different_project)
      end
    end

    User.with_current_user(admin) do
      with_config_value(:hide_details_enabled, false) do
        refute hide_contact_details?(person_same_project)
        refute hide_contact_details?(person_different_project)
        refute hide_contact_details?(project)
        refute hide_contact_details?(different_project)
      end

      with_config_value(:hide_details_enabled, true) do
        assert hide_contact_details?(person_same_project)
        assert hide_contact_details?(person_different_project)
        assert hide_contact_details?(project)
        assert hide_contact_details?(different_project)
      end
    end

  end

end