class Treatment < ActiveRecord::Base
  belongs_to :sample
  belongs_to :specimen
  belongs_to :unit
  belongs_to :time_after_treatment_unit,class_name:"Unit"

  belongs_to :measured_item
  belongs_to :compound

  alias :treatment_type :measured_item

  validates :sample, presence:true

  #MERGENOTE - why?
  TREATMENT_PROTOCOLS = ["NO PERTURBATION","PERTURBATION ROTENONE FISH","PERTURBATION ROTENONE MOUSE","PERTURBATION ROTENONE WORM","PERTURBATION ROTENONE FIBROBLAST"]

  #MERGENOTE - refactor and simplify
  def incubation_time_with_unit
    incubation_time.nil? ? "" : "#{incubation_time} (#{incubation_time_unit.symbol}s)"
  end

  #MERGENOTE - refactor and simplify
  def value_with_unit
    start_value.nil? ? "" : start_value.to_s + " " + (end_value.nil? ? "" : "- " + end_value.to_s + " ") + unit.symbol
  end

end