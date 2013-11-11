class StudiedFactor < ActiveRecord::Base
  include StudiedFactorsHelper
  
  belongs_to :measured_item
  belongs_to :unit
  belongs_to :data_file
  has_many :studied_factor_links, :before_add => proc {|sf,sfl| sfl.studied_factor = sf}, :dependent => :destroy

  validates_presence_of :measured_item,:data_file
  validates_presence_of :studied_factor_links, :if => Proc.new{|fs| fs.measured_item.title == 'concentration'}, :message => "^Substance can't be a empty"
  validates_presence_of :start_value, :unit, :unless => Proc.new{|fs| fs.measured_item.title == 'growth medium' || fs.measured_item.title == 'buffer'}, :message => "^Value can't be a empty"

  acts_as_annotatable :name_field => :title
  include Seek::Taggable

  def range_text
    #TODO: write test
    return start_value unless (end_value && end_value!=0)
    return "#{start_value} to #{end_value}"
  end

  def substances
    studied_factor_links.collect{|l| l.substance}
  end

end
