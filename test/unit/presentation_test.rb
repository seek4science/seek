require 'test_helper'

class PresentationTest < ActiveSupport::TestCase
  test 'validations' do
    presentation = FactoryBot.create :presentation
    presentation.title = ''

    refute presentation.valid?

    presentation.reload

  end

  test "new presentation's version is 1" do
    presentation = FactoryBot.create :presentation
    assert_equal 1, presentation.version
  end

  test 'can create new version of presentation' do
    presentation = FactoryBot.create :presentation
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
    presentation = FactoryBot.create :presentation
    assert presentation.events.empty?

    User.current_user = presentation.contributor
    assert_difference 'presentation.events.count' do
      presentation.events << FactoryBot.create(:event)
    end
  end

  test 'has uuid' do
    presentation = FactoryBot.create :presentation
    assert_not_nil presentation.uuid
  end

  test 'factory using with_project_contributor is still configurable' do
    default_factory_pres = FactoryBot.create(:min_presentation)
    assert default_factory_pres.contributor
    assert default_factory_pres.projects.any?
    assert default_factory_pres.projects.first.has_member?(default_factory_pres.contributor)

    bob = FactoryBot.create(:person)
    bobs_project = bob.projects.first
    specified_contributor_pres = FactoryBot.create(:min_presentation, contributor: bob)
    assert_equal bob, specified_contributor_pres.contributor
    assert_equal bobs_project, specified_contributor_pres.projects.first
    assert specified_contributor_pres.projects.first.has_member?(bob)

    project = FactoryBot.create(:project)
    specified_project_pres = FactoryBot.create(:min_presentation, projects: [project])
    assert specified_project_pres.contributor
    assert_equal project, specified_project_pres.projects.first
    assert specified_project_pres.projects.first.has_member?(specified_project_pres.contributor)

    factory_specified_project_pres = FactoryBot.create(:presentation_with_specified_project)
    assert_equal 'Specified Project', factory_specified_project_pres.projects.first.title
    assert factory_specified_project_pres.contributor
    assert factory_specified_project_pres.projects.any?
    assert factory_specified_project_pres.projects.first.has_member?(factory_specified_project_pres.contributor)
  end
end
