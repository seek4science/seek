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
      # same id, different project. Skip Study and Assay as they inherit project from Investigation
      unless [:study, :assay].include?(factory_name)
        obj3 = FactoryBot.build(factory_name, contributor: contributor2, external_identifier: 'some id', projects: [project2])
        assert obj3.valid?, "#{factory_name} should be valid"
      end
    end
  end

  private
  def factory_names
    [:investigation, :study, :assay, :observation_unit, :data_file, :model, :sop, :presentation, :workflow, :document, :sample, :strain, :collection, :publication, :placeholder, :file_template, :template, :simple_sample_type]
  end
end
