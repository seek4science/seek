require 'test_helper'

class SampleControlledVocabApiTest < ActionDispatch::IntegrationTest
  # include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    admin_login
    login_as(FactoryBot.create(:project_administrator))

    @sample_controlled_vocab = SampleControlledVocab.new({ title:"a title", description:"some description",
                                                           source_ontology: "EFO", ols_root_term_uri: "http://a_uri",
                                                           required: "true", short_name: "short_name" })
                                                           
    @sample_controlled_vocab_term = SampleControlledVocabTerm.new({ label: "organism", iri: "http://some_iri",
                                                                    parent_iri: "http://another_iri" })
    @sample_controlled_vocab.sample_controlled_vocab_terms << @sample_controlled_vocab_term
    @sample_controlled_vocab.save!
  end
end
