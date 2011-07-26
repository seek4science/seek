class ExperimentalCondition < ActiveRecord::Base
  include StudiedFactorsHelper

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  has_many :experimental_condition_links, :before_add => proc {|ec,ecl| ecl.experimental_condition = ec}, :dependent => :destroy

  validates_presence_of :unit,:measured_item,:start_value,:sop
  validates_presence_of :experimental_condition_links, :if => Proc.new{|ec| ec.measured_item.title == 'concentration'}, :message => "can't be a nil"
  acts_as_solr(:field => [], :include => [:measured_item, :substance]) if Seek::Config.solr_enabled


  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end

end
