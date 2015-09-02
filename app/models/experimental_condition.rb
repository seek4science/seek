class ExperimentalCondition < ActiveRecord::Base
  include Seek::ExperimentalFactors::ModelConcerns

  belongs_to :sop
  has_many :experimental_condition_links, :before_add => proc {|ec,ecl| ecl.experimental_condition = ec}, :dependent => :destroy
  alias_attribute :links,:experimental_condition_links

  validates :sop,presence:true

  def range_text
    #TODO: write test
    return start_value
  end

end
