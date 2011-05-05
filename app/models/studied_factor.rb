class StudiedFactor < ActiveRecord::Base

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :data_file
  belongs_to :compound, :polymorphic => true

  validates_presence_of :unit,:measured_item,:start_value,:data_file
  validates_presence_of :compound, :if => :is_concentration?




  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end

  def is_concentration?
    measured_item.title == 'concentration'
  end
end
