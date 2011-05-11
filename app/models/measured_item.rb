class MeasuredItem < ActiveRecord::Base

  has_many :studied_factors
  has_many :experimental_conditions
  named_scope :for_factors_studied?, :conditions => {:factors_studied=>true}

end
