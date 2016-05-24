class SampleControlledVocab < ActiveRecord::Base
  attr_accessible :title, :description, :sample_controlled_vocab_terms_attributes

  has_many :sample_controlled_vocab_terms, inverse_of: :sample_controlled_vocab, dependent: :destroy
  has_many :sample_attributes, inverse_of: :sample_controlled_vocab
  has_many :sample_types, through: :sample_attributes
  has_many :samples, through: :sample_types

  validates :title, presence: true, uniqueness: true

  accepts_nested_attributes_for :sample_controlled_vocab_terms, allow_destroy: true

  grouped_pagination

  def labels
    sample_controlled_vocab_terms.collect(&:label)
  end

  def includes_term?(value)
    labels.include?(value)
  end

  def can_delete?
    sample_types.empty?
  end

  def can_edit?
    samples.empty?
  end
end
