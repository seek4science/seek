class MeasuredItem < ActiveRecord::Base

  has_many :studied_factors
  has_many :experimental_conditions
  scope :factors_studied_items, :conditions => {:factors_studied=>true}

end
