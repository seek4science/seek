class Treatment < ActiveRecord::Base

  belongs_to :sample
  belongs_to :specimen
  belongs_to :compound
  belongs_to :unit

  belongs_to :incubation_time_unit, :class_name => "Unit", :foreign_key => "incubation_time_unit_id"
  belongs_to :type, :class_name => "MeasuredItem", :foreign_key => "type"


  TREATMENT_PROTOCOLS = ["NO PERTURBATION","PERTURBATION ROTENONE FISH","PERTURBATION ROTENONE MOUSE","PERTURBATION ROTENONE WORM","PERTURBATION ROTENONE FIBROBLAST"]
end