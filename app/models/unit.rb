class Unit < ActiveRecord::Base

  has_many :studied_factors
  has_many :experimental_conditions

end
