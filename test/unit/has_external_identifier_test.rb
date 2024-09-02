require 'test_helper'

class HasExternalIdentifierTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  test 'field present on relevant types' do
    contributor = FactoryBot.create(:person)

    affected_types.each do |type|
      factory_name = type.name.underscore.to_sym
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

    affected_types.each do |type|
      factory_name = type.name.underscore.to_sym
      obj = FactoryBot.create(factory_name, contributor: contributor1, external_identifier: 'some id')
      assert obj.valid?, "#{type.name} should be valid"
      obj2 = FactoryBot.build(factory_name, contributor: contributor1, external_identifier: 'some id')
      assert_equal obj.projects, obj2.projects, "#{type.name} projects should match"
      refute obj2.valid?, "#{type.name} should not be valid"
      obj2.external_identifier = 'some other id'
      assert obj2.valid?, "#{type.name} should be valid"
      # same id, different project. Skip Study and Assay as they inherit project from Investigation
      unless [Study, Assay].include?(type)
        obj3 = FactoryBot.build(factory_name, contributor: contributor2, external_identifier: 'some id', projects: [project2])
        assert obj3.valid?, "#{type.name} should be valid"
      end
    end
  end

  private
  def affected_types
    [Investigation, Study, Assay, ObservationUnit, DataFile, Model, Sop, Presentation, Workflow, Document, Sample, Strain]
  end
end
