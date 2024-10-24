require 'test_helper'

class HasExternalIdentifierTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  test 'field present on relevant types' do
    contributor = FactoryBot.create(:person)

    factory_names.each do |factory_name|
      obj = FactoryBot.create(factory_name, contributor: contributor)
      assert obj.respond_to?(:external_identifier)
      User.with_current_user(contributor.user) do
        obj.external_identifier = 'some identifier'
        assert obj.valid?
        assert obj.save
        obj.reload
        assert_equal 'some identifier', obj.external_identifier
      end
    end
  end

  test 'validate uniq in scope of projects' do
    contributor1 = FactoryBot.create(:person)
    contributor2 = FactoryBot.create(:person)
    project2 = contributor2.projects.first

    factory_names.each do |factory_name|
      obj = FactoryBot.create(factory_name, contributor: contributor1, external_identifier: 'some id')
      assert obj.valid?, "#{factory_name} should be valid"
      obj2 = FactoryBot.build(factory_name, contributor: contributor1, external_identifier: 'some id')
      assert_equal obj.projects, obj2.projects, "#{factory_name} projects should match"
      refute obj2.valid?, "#{factory_name} should not be valid"
      assert_equal ['is not unique within the scope of the associated Projects'], obj2.errors[:external_identifier]
      obj2.external_identifier = 'some other id'
      assert obj2.valid?, "#{factory_name} should be valid"
      # same id, different project. Skip Study, ObservationUnit and Assay as they inherit project from Investigation
      unless [:study, :observation_unit, :assay].include?(factory_name)
        obj3 = FactoryBot.build(factory_name, contributor: contributor2, external_identifier: 'some id', projects: [project2])
        assert obj3.valid?, "#{factory_name} should be valid"
      end
    end
  end

  test 'by_external_identifier' do
    contributor1 = FactoryBot.create(:person)
    contributor2 = FactoryBot.create(:person)
    project1 = contributor1.projects.first
    project2 = contributor2.projects.first
    other_project = FactoryBot.create(:project)
    factory_names.each do |factory_name|
      obj1 = FactoryBot.create(factory_name, contributor: contributor1, external_identifier: 'some id')
      obj2 = FactoryBot.create(factory_name, contributor: contributor2, external_identifier: 'some id')
      obj3 = FactoryBot.create(factory_name, contributor: contributor2, external_identifier: 'some other id')
      model = obj1.class
      assert_equal obj1, model.by_external_identifier('some id', [project1]), "#{factory_name} should find by id"
      assert_equal obj2, model.by_external_identifier('some id', [project2]), "#{factory_name} should find by id"
      assert_equal obj3, model.by_external_identifier('some other id', [project2]), "#{factory_name} should find by id"
      assert_nil model.by_external_identifier('some other id', [project1]), "#{factory_name} should not find by id in another project"
      assert_nil model.by_external_identifier('some id', [other_project]), "#{factory_name} should not find by id in another project"
      assert_nil model.by_external_identifier('non existing id', [project1]), "#{factory_name} should not find by id that doesnt exist"
    end
  end

  test 'by external identifier multiple projects' do
    contributor1 = FactoryBot.create(:person)
    contributor2 = FactoryBot.create(:person)
    project1 = contributor1.projects.first
    project2 = contributor2.projects.first
    other_project = FactoryBot.create(:project)
    sop1 = FactoryBot.create(:sop, contributor: contributor1, projects: [project1], external_identifier: 'some id')
    sop2 = FactoryBot.create(:sop, contributor: contributor1, projects: [other_project, project2], external_identifier: 'some other id')

    assert_equal sop1, Sop.by_external_identifier('some id', [project1])
    assert_equal sop1, Sop.by_external_identifier('some id', [project1, other_project])
    assert_nil Sop.by_external_identifier('some id', [project2])
    assert_equal sop2, Sop.by_external_identifier('some other id', [other_project, project2])
    assert_equal sop2, Sop.by_external_identifier('some other id', [other_project, project1])
    assert_nil Sop.by_external_identifier('some other id', [project1])
  end

  private
  def factory_names
    [:investigation, :study, :assay, :observation_unit, :data_file, :model, :sop, :presentation, :workflow, :document, :sample, :strain, :collection, :publication, :placeholder, :file_template, :template, :simple_sample_type]
  end
end
