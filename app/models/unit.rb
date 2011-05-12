class Unit < ActiveRecord::Base

  has_many :studied_factors
  has_many :experimental_conditions
  named_scope :factors_studied_units,:conditions=>{:factors_studied=>true}

end
