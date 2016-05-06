class SampleControlledVocab < ActiveRecord::Base
  attr_accessible :title, :description

  has_many :sample_controlled_vocab_terms, inverse_of: :sample_controlled_vocab

  validates :title, presence: true, uniqueness: true

  def labels
    sample_controlled_vocab_terms.collect(&:label)
  end

  def includes_term?(value)
    labels.include?(value)
  end
end
