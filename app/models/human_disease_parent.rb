class HumanDiseaseParent < ApplicationRecord
  belongs_to :parent, foreign_key: 'parent_id', class_name: 'HumanDisease'
  belongs_to :child, foreign_key: 'human_disease_id', class_name: 'HumanDisease'

  validates_presence_of :parent
  validates_presence_of :child

  scope :matches_for, -> (child, parent) do
    where("human_disease_id = ? AND parent_id = ?", child.id, parent.id)
  end

  def self.exists_for? child,parent
    !HumanDiseaseParent.matches_for(child, parent).empty?
  end
end
