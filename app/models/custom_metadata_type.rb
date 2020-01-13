class CustomMetadataType < ApplicationRecord
  has_many :custom_metadata_attributes, inverse_of: :custom_metadata_type

  validates :title, presence: true
  validates :custom_metadata_attributes, presence: true
  validates :supported_type, presence: true
  validate :supported_type_must_be_valid_type

  private

  def supported_type_must_be_valid_type
    return if supported_type.blank? # already convered by presence validation
    valid = true
    begin
      clz = supported_type.constantize
      # TODO: in the future to check it is a supported active record type
      valid = clz.ancestors.include?(ActiveRecord::Base)
    rescue NameError
      valid = false
    end
    unless valid
      errors.add(:supported_type, 'is not a type that can supported custom metadata')
    end
  end
end
