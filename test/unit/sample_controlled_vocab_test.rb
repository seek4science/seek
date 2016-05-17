require 'test_helper'

class SampleControlledVocabTest < ActiveSupport::TestCase
  test 'association with terms' do
    vocab = SampleControlledVocab.new(title: 'test')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
    vocab.save!
    vocab = SampleControlledVocab.find(vocab.id)
    assert_equal ['fish'], vocab.sample_controlled_vocab_terms.collect(&:label)
  end

  test 'labels' do
    vocab = SampleControlledVocab.new(title: 'test')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'sprout')
    vocab.save!
    assert_equal %w(fish sprout), vocab.labels.sort
  end

  test 'validation' do
    vocab = SampleControlledVocab.new
    refute vocab.valid?
    vocab.title = 'test'
    assert vocab.valid?
    vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
    assert vocab.valid?
    vocab.save!
    vocab2 = SampleControlledVocab.new(title: 'test')
    refute vocab2.valid?
  end

  test 'apples factory' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.title.start_with?('apples controlled vocab')
    assert_equal ['Golden Delicious', 'Granny Smith', 'Bramley', "Cox's Orange Pippin"].sort, apples.labels.sort
  end

  test 'includes term?' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.includes_term?('Bramley')
    refute apples.includes_term?('Fish')
  end

  test 'destroy' do
    cv = Factory(:apples_sample_controlled_vocab)
    assert_difference('SampleControlledVocab.count', -1) do
      assert_difference('SampleControlledVocabTerm.count', -4) do
        assert cv.destroy
      end
    end
  end

  test 'cannot destroy if linked to sample type' do
    type = Factory(:apples_controlled_vocab_sample_type)
    cv = type.sample_attributes.first.sample_controlled_vocab
    refute cv.can_delete?
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        refute cv.destroy
      end
    end
  end

  test 'can edit' do
    cv = Factory(:apples_sample_controlled_vocab, title: 'for can_edit test')
    assert cv.can_edit?

    type = Factory(:apples_controlled_vocab_sample_type, title: 'type for can_edit test')
    cv = type.sample_attributes.first.sample_controlled_vocab
    assert cv.can_edit?

    # cannot edit if linked to samples
    sample = Sample.new(sample_type: Factory(:apples_controlled_vocab_sample_type, title: 'type for can_edit test2'), title: 'testing cv can edit')
    sample.set_attribute(:apples, 'Bramley')
    disable_authorization_checks do
      assert sample.save!
    end

    cv = sample.sample_type.sample_attributes.first.sample_controlled_vocab
    refute cv.can_edit?
  end
end
