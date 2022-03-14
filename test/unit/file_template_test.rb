require 'test_helper'

class FileTemplateTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    person = Factory(:person)
    p = person.projects.first
    s = Factory(:file_template, projects: [p], contributor:person)
    assert_equal p, s.projects.first
  end

  test 'title trimmed' do
    file_template = Factory(:file_template, title: ' test template')
    assert_equal('test template', file_template.title)
  end

  test 'validation' do
    asset = FileTemplate.new title: 'fred', projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert asset.valid?

    asset = FileTemplate.new projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert !asset.valid?
  end

  test 'avatar key' do
    assert_nil  Factory(:file_template).avatar_key
    assert  Factory(:file_template).use_mime_type_for_avatar?

    assert_nil  Factory(:file_template_version).avatar_key
    assert  Factory(:file_template_version).use_mime_type_for_avatar?
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      file_template = Factory.build(:file_template)
      refute file_template.persisted?
      file_template.save!
      file_template.reload
      assert file_template.valid?
      assert file_template.policy.valid?
      assert_equal Policy::NO_ACCESS, file_template.policy.access_type
      assert file_template.policy.permissions.blank?
    end
  end

  test 'version created for new file template' do
    person = Factory(:person)

    User.with_current_user(person.user) do
      file_template = Factory(:file_template, contributor:person)

      assert file_template.save

      file_template = FileTemplate.find(file_template.id)

      assert_equal 1, file_template.version
      assert_equal 1, file_template.versions.size
      assert_equal file_template, file_template.versions.last.file_template
      assert_equal file_template.title, file_template.versions.first.title
    end

  end

  test 'create new version' do
    file_template = Factory(:file_template)
    User.current_user = file_template.contributor
    file_template.save!
    file_template = FileTemplate.find(file_template.id)
    assert_equal 1, file_template.version
    assert_equal 1, file_template.versions.size
    assert_equal 'This FileTemplate', file_template.title

    file_template.save!
    file_template = FileTemplate.find(file_template.id)

    assert_equal 1, file_template.version
    assert_equal 1, file_template.versions.size
    assert_equal 'This FileTemplate', file_template.title

    file_template.title = 'Updated FileTemplate'

    file_template.save_as_new_version('Updated file_template as part of a test')
    file_template = FileTemplate.find(file_template.id)
    assert_equal 2, file_template.version
    assert_equal 2, file_template.versions.size
    assert_equal 'Updated FileTemplate', file_template.title
    assert_equal 'Updated FileTemplate', file_template.versions.last.title
    assert_equal 'Updated file_template as part of a test', file_template.versions.last.revision_comments
    assert_equal 'This FileTemplate', file_template.versions.first.title

    assert_equal 'This FileTemplate', file_template.find_version(1).title
    assert_equal 'Updated FileTemplate', file_template.find_version(2).title
  end

  test 'project for file_template and file_template version match' do
    person = Factory(:person)
    project = person.projects.first
    file_template = Factory(:file_template, projects: [project], contributor:person)
    assert_equal project, file_template.projects.first
    assert_equal project, file_template.latest_version.projects.first
  end

  test 'assign projects' do
    person = Factory(:person)
    project = person.projects.first
    User.with_current_user(person.user) do
      file_template = Factory(:file_template, projects: [project],contributor:person)
      person.add_to_project_and_institution(Factory(:project),person.institutions.first)
      projects = person.projects
      assert_equal 2,projects.count
      file_template.update_attributes(project_ids: projects.map(&:id))
      file_template.save!
      file_template.reload
      assert_equal projects.sort, file_template.projects.sort
    end
  end

  test 'versions destroyed as dependent' do
    file_template = Factory(:file_template)
    assert_equal 1, file_template.versions.size, 'There should be 1 version of this FileTemplate'
    assert_difference(['FileTemplate.count', 'FileTemplate::Version.count'], -1) do
      User.current_user = file_template.contributor
      file_template.destroy
    end
  end

  test 'test uuid generated' do
    x = Factory.build(:file_template)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = Factory.build(:file_template)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing user' do
    file_template = Factory :file_template, contributor: Factory(:person)
    assert file_template.contributor
    assert_equal file_template.contributor.user, file_template.contributing_user
    assert_equal file_template.contributor.user, file_template.latest_version.contributing_user
  end

end
