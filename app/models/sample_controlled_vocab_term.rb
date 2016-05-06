class SampleControlledVocabTerm < ActiveRecord::Base
  attr_accessible :label, :sample_controlled_vocab_id, :sample_controlled_vocab

  belongs_to :sample_controlled_vocab, inverse_of: :sample_controlled_vocab_terms

  validates :label, presence: true
end
