require 'test_helper'

class ExternalSearchTest < ActiveSupport::TestCase

  test 'search adaptors' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors
    assert adaptors.size > 0
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
    an_instance = adaptors.find { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }
    assert an_instance.is_a?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal 'BioModels Database', an_instance.name

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'models'
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'data_files'
    assert adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
  end

  test 'search adaptor names' do
    assert_equal ['BioModels Database'], Seek::ExternalSearch.instance.search_adaptor_names('all')
    assert_equal ['BioModels Database'], Seek::ExternalSearch.instance.search_adaptor_names
    assert_equal ['BioModels Database'], Seek::ExternalSearch.instance.search_adaptor_names('models')
    assert_equal [], Seek::ExternalSearch.instance.search_adaptor_names('sops')
  end

  private


end
