class Treatment < ActiveRecord::Base


  belongs_to :sample
  belongs_to :specimen
  belongs_to :compound
  belongs_to :unit

  belongs_to :incubation_time_unit, :class_name => "Unit", :foreign_key => "incubation_time_unit_id"

  belongs_to :treatment_type, :class_name => "MeasuredItem", :foreign_key => "treatment_type_id"


  TREATMENT_PROTOCOLS = ["NO PERTURBATION","PERTURBATION ROTENONE FISH","PERTURBATION ROTENONE MOUSE","PERTURBATION ROTENONE WORM","PERTURBATION ROTENONE FIBROBLAST"]

  def incubation_time_with_unit
    incubation_time.nil? ? "" : "#{incubation_time} (#{incubation_time_unit.symbol}s)"
  end

  def value_with_unit
    start_value.nil? ? "" : start_value.to_s + " " + (end_value.nil? ? "" : "- " + end_value.to_s + " ") + unit.symbol
  end

end