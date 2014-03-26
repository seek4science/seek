class Treatment < ActiveRecord::Base
  belongs_to :sample
  belongs_to :unit

  belongs_to :measured_item
  belongs_to :compound

  alias :treatment_type :measured_item

  validates :sample, presence:true

  TREATMENT_PROTOCOLS = ["NO PERTURBATION","PERTURBATION ROTENONE FISH","PERTURBATION ROTENONE MOUSE","PERTURBATION ROTENONE WORM","PERTURBATION ROTENONE FIBROBLAST"]
end