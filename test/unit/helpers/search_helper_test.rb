require 'test_helper'

class SearchHelperTest < ActionView::TestCase

  test "search adaptors" do
    adaptors = search_adaptors
    assert adaptors.size > 0
    assert !adaptors.select{|a| a.kind_of?(Seek::SearchBiomodelsAdaptor)}.empty?
    an_instance = adaptors.select{|a| a.kind_of?(Seek::SearchBiomodelsAdaptor)}.first
    assert an_instance.kind_of?(Seek::SearchAdaptor)

    adaptors = search_adaptors "models"
    assert !adaptors.select{|a| a.kind_of?(Seek::SearchBiomodelsAdaptor)}.empty?

    adaptors = search_adaptors "data_files"
    assert adaptors.select{|a| a.kind_of?(Seek::SearchBiomodelsAdaptor)}.empty?
  end
end