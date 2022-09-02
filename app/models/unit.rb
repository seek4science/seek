class Unit < ApplicationRecord

  scope :time_units, -> { where(comment: 'time') }

  def dimensionless?
    symbol=="dimensionless"
  end

  def to_s
    title ? title : symbol
  end

end
