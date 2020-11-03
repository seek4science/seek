class SampleControlledVocabTerm < ApplicationRecord
  # attr_accessible :label, :sample_controlled_vocab_id, :sample_controlled_vocab, :_destroy

  belongs_to :sample_controlled_vocab, inverse_of: :sample_controlled_vocab_terms
  has_many :ontology_labels, dependent: :destroy

  accepts_nested_attributes_for :ontology_labels, allow_destroy: true


  validates :label, presence: true
end
