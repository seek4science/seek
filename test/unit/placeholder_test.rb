require 'test_helper'

class PlaceholderTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    person = Factory(:person)
    p = person.projects.first
    s = Factory(:placeholder, projects: [p], contributor:person)
    assert_equal p, s.projects.first
  end

  test 'title trimmed' do
    placeholder = Factory(:placeholder, title: ' test placeholder')
    assert_equal('test placeholder', placeholder.title)
  end

  test 'validation' do
    asset = Placeholder.new title: 'fred', projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert asset.valid?

    asset = Placeholder.new projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert !asset.valid?
  end

  test 'assay association' do
    placeholder = Factory(:placeholder, policy: Factory(:publicly_viewable_policy))
    assay = assays(:modelling_assay_with_data_and_relationship)
    assay_asset = assay_assets(:metabolomics_assay_asset1)
    assert_not_equal assay_asset.asset, placeholder
    assert_not_equal assay_asset.assay, assay
    assay_asset.asset = placeholder
    assay_asset.assay = assay
    User.with_current_user(assay.contributor.user) { assay_asset.save! }
    assay_asset.reload
    assert assay_asset.valid?
    assert_equal assay_asset.asset, placeholder
    assert_equal assay_asset.assay, assay
  end

  test 'avatar key' do
    assert  Factory(:placeholder).avatar_key
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      placeholder = Factory.build(:placeholder)
      refute placeholder.persisted?
      placeholder.save!
      placeholder.reload
      assert placeholder.valid?
      assert placeholder.policy.valid?
      assert_equal Policy::NO_ACCESS, placeholder.policy.access_type
      assert placeholder.policy.permissions.blank?
    end
  end

  test 'assign projects' do
    person = Factory(:person)
    project = person.projects.first
    User.with_current_user(person.user) do
      placeholder = Factory(:placeholder, projects: [project],contributor:person)
      person.add_to_project_and_institution(Factory(:project),person.institutions.first)
      projects = person.projects
      assert_equal 2,projects.count
      placeholder.update_attributes(project_ids: projects.map(&:id))
      placeholder.save!
      placeholder.reload
      assert_equal projects.sort, placeholder.projects.sort
    end
  end

  test 'test uuid generated' do
    x = Factory.build(:placeholder)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = Factory.build(:placeholder)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing user' do
    placeholder = Factory :placeholder, contributor: Factory(:person)
    assert placeholder.contributor
    assert_equal placeholder.contributor.user, placeholder.contributing_user
  end
end
