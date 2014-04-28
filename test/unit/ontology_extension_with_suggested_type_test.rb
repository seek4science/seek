require 'test_helper'

class OntologyExtensionWithSuggestedTypeTest < ActiveSupport::TestCase
  test "assay types from ontology cannot be edited or deleted" do
         Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri.each do |uri, clazz|
             User.current_user = Factory :user, :person => Factory(:admin)
             assert_equal false, clazz.can_edit?
             assert_equal false, clazz.can_destroy?
             User.current_user = Factory :user
             assert_equal false, clazz.can_edit?
             assert_equal false, clazz.can_destroy?
         end
         Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri.each do |uri, clazz|
           User.current_user = Factory :user, :person => Factory(:admin)
           assert_equal false, clazz.can_edit?
           assert_equal false, clazz.can_destroy?
           User.current_user = Factory :user
           assert_equal false, clazz.can_edit?
           assert_equal false, clazz.can_destroy?
         end
  end

  test "technology types from ontology cannot be edited or deleted" do
           Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri.each do |uri, clazz|
               User.current_user = Factory :user, :person => Factory(:admin)
               assert_equal false, clazz.can_edit?
               assert_equal false, clazz.can_destroy?
               User.current_user = Factory :user
               assert_equal false, clazz.can_edit?
               assert_equal false, clazz.can_destroy?
           end
    end

end