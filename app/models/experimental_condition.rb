class ExperimentalCondition < ActiveRecord::Base
  include StudiedFactorsHelper

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :substance, :polymorphic => true

  validates_presence_of :unit,:measured_item,:start_value,:sop
  validates_presence_of :substance, :if => Proc.new{|e| e.measured_item.title == 'concentration'}, :message => 'can not be blank or multiple'

  acts_as_solr(:field => [], :include => [:measured_item, :substance]) if Seek::Config.solr_enabled


  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end

end
