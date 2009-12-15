class ExperimentalCondition < ActiveRecord::Base

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit

  validates_presence_of :unit,:measured_item,:start_value,:sop
  
  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end
end
