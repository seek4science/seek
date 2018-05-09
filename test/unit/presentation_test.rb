require 'test_helper'

class PresentationTest < ActiveSupport::TestCase
  test 'validations' do
    presentation = Factory :presentation
    presentation.title = ''

    assert !presentation.valid?

    presentation.reload

    # VL only:allow no projects
    as_virtualliver do
      presentation.projects.clear
      assert presentation.valid?
    end
  end

  test "new presentation's version is 1" do
    presentation = Factory :presentation
    assert_equal 1, presentation.version
  end

  test 'can create new version of presentation' do
    presentation = Factory :presentation
    old_attrs = presentation.attributes

    disable_authorization_checks do
      presentation.save_as_new_version('new version')
    end

    assert_equal 1, old_attrs['version']
    assert_equal 2, presentation.version

    old_attrs.delete('version')
    new_attrs = presentation.attributes
    new_attrs.delete('version')

    old_attrs.delete('updated_at')
    new_attrs.delete('updated_at')

    old_attrs.delete('created_at')
    new_attrs.delete('created_at')

    assert_equal old_attrs, new_attrs
  end

  test 'event association' do
    presentation = Factory :presentation
    assert presentation.events.empty?

    User.current_user = presentation.contributor
    assert_difference 'presentation.events.count' do
      presentation.events << Factory(:event)
    end
  end

  test 'has uuid' do
    presentation = Factory :presentation
    assert_not_nil presentation.uuid
  end

  test 'factory using with_project_contributor is still configurable' do
    default_factory_pres = Factory(:min_presentation)
    assert default_factory_pres.contributor
    assert default_factory_pres.projects.any?
    assert default_factory_pres.projects.first.has_member?(default_factory_pres.contributor)

    bob = Factory(:person)
    bobs_project = bob.projects.first
    specified_contributor_pres = Factory(:min_presentation, contributor: bob)
    assert_equal bob, specified_contributor_pres.contributor
    assert_equal bobs_project, specified_contributor_pres.projects.first
    assert specified_contributor_pres.projects.first.has_member?(bob)

    project = Factory(:project)
    specified_project_pres = Factory(:min_presentation, projects: [project])
    assert specified_project_pres.contributor
    assert_equal project, specified_project_pres.projects.first
    assert specified_project_pres.projects.first.has_member?(specified_project_pres.contributor)
  end
end
