require "test_helper"

class ExternalSearchTest < ActiveSupport::TestCase

  include Seek::ExternalSearch

  test "search adaptors" do
    adaptors = search_adaptors
    assert adaptors.size > 0
    assert !adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?
    an_instance = adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.first
    assert an_instance.kind_of?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal "BioModels Database",an_instance.name

    adaptors = search_adaptors "models"
    assert !adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?

    adaptors = search_adaptors "data_files"
    assert adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?
  end

  test "search adaptor names" do
    assert_equal ["BioModels Database"],search_adaptor_names("all")
    assert_equal ["BioModels Database"],search_adaptor_names
    assert_equal ["BioModels Database"],search_adaptor_names("models")
    assert_equal [],search_adaptor_names("sops")
  end
end