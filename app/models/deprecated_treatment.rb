class DeprecatedTreatment < ActiveRecord::Base
  belongs_to :unit
  belongs_to :time_after_treatment_unit, class_name: 'Unit'

  belongs_to :measured_item
  belongs_to :compound

  alias_method :treatment_type, :measured_item

  validates :sample, presence: true

  # DEPRECATED
  belongs_to :deprecated_sample
  belongs_to :deprecated_specimen

  def incubation_time_with_unit
    incubation_time ? "#{incubation_time} (#{incubation_time_unit.symbol}s)" : ''
  end

  def value_with_unit
    start_value ? start_value.to_s + ' ' + (end_value.nil? ? '' : '- ' + end_value.to_s + ' ') + unit.symbol : ''
  end
end
