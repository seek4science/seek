require 'test_helper'

class OntologyExtensionWithSuggestedTypeTest < ActiveSupport::TestCase
  test 'assay types from ontology cannot be edited or deleted' do
    Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri.each do |_uri, clazz|
      User.current_user = FactoryBot.create :user, person: FactoryBot.create(:admin)
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
      User.current_user = FactoryBot.create :user
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
    end
    Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri.each do |_uri, clazz|
      User.current_user = FactoryBot.create :user, person: FactoryBot.create(:admin)
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
      User.current_user = FactoryBot.create :user
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
    end
  end

  test 'technology types from ontology cannot be edited or deleted' do
    Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri.each do |_uri, clazz|
      User.current_user = FactoryBot.create :user, person: FactoryBot.create(:admin)
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
      User.current_user = FactoryBot.create :user
      assert !clazz.can_edit?
      assert !clazz.can_destroy?
    end
  end
end
