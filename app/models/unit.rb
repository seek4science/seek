class Unit < ActiveRecord::Base

  has_many :studied_factors
  has_many :experimental_conditions
  scope :factors_studied_units, -> { where(factors_studied: true) }
  scope :time_units, -> { where(comment: 'time') }

  def dimensionless?
    symbol=="dimensionless"
  end

  def to_s
    title ? title : symbol
  end

end
