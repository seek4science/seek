require "test_helper"

class ExternalSearchTest < ActiveSupport::TestCase

  include Seek::ExternalSearch

  test "search adaptors" do
    adaptors = search_adaptors
    assert adaptors.size > 0
    assert !adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?
    an_instance = adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.first
    assert an_instance.kind_of?(Seek::AbstractSearchAdaptor)

    adaptors = search_adaptors "models"
    assert !adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?

    adaptors = search_adaptors "data_files"
    assert adaptors.select{|a| a.kind_of?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor)}.empty?
  end
end