class StudiedFactor < ActiveRecord::Base
  include StudiedFactorsHelper

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :data_file
  has_many :studied_factor_links, :before_add => proc {|sf,sfl| sfl.studied_factor = sf}, :dependent => :destroy

  validates_presence_of :unit,:measured_item,:start_value,:data_file
  validates_presence_of :studied_factor_links, :if => Proc.new{|fs| fs.measured_item.title == 'concentration'}, :message => "can't be a nil"
  acts_as_solr(:field => [], :include => [:measured_item, :substance]) if Seek::Config.solr_enabled

  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end
end
