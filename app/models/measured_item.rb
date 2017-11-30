class MeasuredItem < ActiveRecord::Base
  has_many :studied_factors
  has_many :experimental_conditions
  scope :factors_studied_items, -> { where(factors_studied: true) }

  # determines the RDF class according to the measured item type
  def rdf_type_entity_fragment
    Seek::Rdf::JERMVocab.measured_item_entity_fragment(title)
  end
end
