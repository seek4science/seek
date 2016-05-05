require 'test_helper'

class SampleControlledVocabTest < ActiveSupport::TestCase

  test 'association with terms' do
    vocab=SampleControlledVocab.new(title: 'test')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label:'fish')
    vocab.save!
    vocab = SampleControlledVocab.find(vocab.id)
    assert_equal ['fish'],vocab.sample_controlled_vocab_terms.collect(&:label)
  end

  test 'labels' do
    vocab=SampleControlledVocab.new(title: 'test')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label:'fish')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label:'sprout')
    vocab.save!
    assert_equal %w(fish sprout),vocab.labels.sort
  end

  test 'validation' do
    vocab=SampleControlledVocab.new
    refute vocab.valid?
    vocab.title='test'
    assert vocab.valid?
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label:'fish')
    assert vocab.valid?
    vocab.save!
    vocab2=SampleControlledVocab.new(title:'test')
    refute vocab2.valid?
  end

  test 'apples factory' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.title.start_with?('apples controlled vocab')
    assert_equal ['Golden Delicious','Granny Smith','Bramley',"Cox's Orange Pippin"].sort,apples.labels.sort
  end

  test 'includes term?' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.includes_term?('Bramley')
    refute apples.includes_term?('Fish')
  end

end
