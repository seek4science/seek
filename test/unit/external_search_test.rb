require 'test_helper'

class ExternalSearchTest < ActiveSupport::TestCase

  test 'search adaptors' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors
    assert adaptors.any?
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
    an_instance = adaptors.find { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }
    assert an_instance.is_a?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal 'BioModels Database', an_instance.name

    assert !adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?
    an_instance = adaptors.find { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }
    assert an_instance.is_a?(Seek::AbstractSearchAdaptor)
    assert an_instance.enabled?
    assert_equal 'ELIXIR TeSS Events', an_instance.name

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'models'
    assert !adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'events'
    assert !adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?

    adaptors = Seek::ExternalSearch.instance.search_adaptors 'data_files'
    assert adaptors.select { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }.empty?
    assert adaptors.select { |a| a.is_a?(Seek::TessSearch::SearchTessAdaptor) }.empty?
  end

  test 'enabled?' do
    adaptors = Seek::ExternalSearch.instance.search_adaptors
    biomodels_adaptor = adaptors.find { |a| a.is_a?(Seek::BiomodelsSearch::SearchBiomodelsAdaptor) }

    Seek::Config.external_search_adaptors = { 'biomodels' => { 'enabled' => true } }
    assert biomodels_adaptor.enabled?

    Seek::Config.external_search_adaptors = { 'biomodels' => { 'enabled' => false } }
    refute biomodels_adaptor.enabled?
  end


  test 'search adaptor names' do
    assert (['BioModels Database', 'ELIXIR TeSS Events'] - Seek::ExternalSearch.instance.search_adaptor_names('all')).blank?
    assert (['BioModels Database', 'ELIXIR TeSS Events'] - Seek::ExternalSearch.instance.search_adaptor_names).blank?
    assert_equal ['BioModels Database'], Seek::ExternalSearch.instance.search_adaptor_names('models')
    assert_equal ['ELIXIR TeSS Events'], Seek::ExternalSearch.instance.search_adaptor_names('events')
    assert_equal [], Seek::ExternalSearch.instance.search_adaptor_names('sops')
  end


end
