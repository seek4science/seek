require 'test_helper'

class HasExternalIdentifierTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  test 'field present on relevant types' do
    types = [Investigation, Study, Assay, ObservationUnit, DataFile, Model, Sop, Presentation, Workflow, Document, Sample, Strain]
    contributor = FactoryBot.create(:person)

    types.each do |type|
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
end
