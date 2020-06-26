class AssayHumanDisease < ActiveRecord::Base
  belongs_to :assay, inverse_of: :assay_human_diseases
  belongs_to :human_disease, inverse_of: :assay_human_diseases

  validates_presence_of :assay
  validates_presence_of :human_disease

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :assay

  scope :matches_for, -> (human_disease, assay) do
    where("assay_id = ? AND human_disease_id = ?", assay.id, human_disease.id)
  end

  def self.exists_for? human_disease,assay
    !AssayHumanDisease.matches_for(human_disease,assay).empty?
  end
end
