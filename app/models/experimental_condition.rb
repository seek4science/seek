class ExperimentalCondition < ActiveRecord::Base
  include StudiedFactorsHelper

  belongs_to :sop  
  belongs_to :measured_item
  belongs_to :unit
  has_many :experimental_condition_links, :before_add => proc {|ec,ecl| ecl.experimental_condition = ec}, :dependent => :destroy

  validates_presence_of :measured_item,:sop
  validates_presence_of :experimental_condition_links, :if => Proc.new{|ec| ec.measured_item.title == 'concentration'}, :message => "^Substance can't be blank"
  validates_presence_of :start_value, :unit, :unless => Proc.new{|ec| ec.measured_item.title == 'growth medium' || ec.measured_item.title == 'buffer'}, :message => "^Value can't be a empty"

  acts_as_annotatable :name_field => :title
  include Seek::Taggable

  def range_text
    #TODO: write test
    return start_value
  end

  def substances
    experimental_condition_links.collect{|l| l.substance}
  end
end
