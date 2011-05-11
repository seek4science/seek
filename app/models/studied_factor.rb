class StudiedFactor < ActiveRecord::Base
  include StudiedFactorsHelper

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :data_file
  belongs_to :substance, :polymorphic => true

  validates_presence_of :unit,:measured_item,:start_value,:data_file
  validates_presence_of :substance, :if => Proc.new{|fs| fs.measured_item.title == 'concentration'}

  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end
end
