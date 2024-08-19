class SampleControlledVocabTerm < ApplicationRecord
  belongs_to :sample_controlled_vocab, inverse_of: :sample_controlled_vocab_terms

  validates :label, presence: true, length: { maximum: 500 }, uniqueness: { scope: :sample_controlled_vocab_id }

  before_validation :truncate_label

  acts_as_annotation_value content_field: :iri

  delegate :ontology_based?, to: :sample_controlled_vocab, allow_nil: true

  private

  def truncate_label
    self.label = label.truncate(500) if label && label.length > 500
  end
end
