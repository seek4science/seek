require 'test_helper'

class SampleControlledVocabTermTest < ActiveSupport::TestCase
  test 'validation' do
    term = SampleControlledVocabTerm.new
    refute term.valid?
    term.label = 'fish'
    assert term.valid?
  end

  test 'ontology_based?' do
    term = FactoryBot.create(:apples_sample_controlled_vocab).sample_controlled_vocab_terms.first
    refute term.ontology_based?

    term = FactoryBot.create(:topics_controlled_vocab).sample_controlled_vocab_terms.first
    assert term.ontology_based?

    term = SampleControlledVocabTerm.new
    refute term.ontology_based?
  end

end
