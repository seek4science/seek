class Treatment < ActiveRecord::Base
  belongs_to :sample
  belongs_to :unit

  validates :sample, presence:true

  TREATMENT_PROTOCOLS = ["NO PERTURBATION","PERTURBATION ROTENONE FISH","PERTURBATION ROTENONE MOUSE","PERTURBATION ROTENONE WORM","PERTURBATION ROTENONE FIBROBLAST"]
end