require 'test_helper'

class SampleControlledVocabApiTest < ActionDispatch::IntegrationTest
  # include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login(FactoryBot.create(:project_administrator))

    disable_authorization_checks do
      @sample_controlled_vocab = SampleControlledVocab.new(title: 'title', description:'some description',
                                                           source_ontology: 'EFO', ols_root_term_uris: 'http://a_uri',
                                                           short_name: 'short_name')

      @sample_controlled_vocab_term = SampleControlledVocabTerm.new(label: 'organism', iri: 'http://some_iri',
                                                                      parent_iri: 'http://another_iri')
      @sample_controlled_vocab.sample_controlled_vocab_terms << @sample_controlled_vocab_term
      @sample_controlled_vocab.save!
    end
  end

  def private_resource
    # setting the key to a known key will make it a system vocab which isn't editable or deletable
    @sample_controlled_vocab.update_column(:key, SampleControlledVocab::SystemVocabs.database_key_for_property(:topics))
    refute @sample_controlled_vocab.can_edit?
    refute @sample_controlled_vocab.can_delete?
    @sample_controlled_vocab
  end
end
