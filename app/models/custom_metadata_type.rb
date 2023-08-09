class CustomMetadataType < ApplicationRecord
  has_many :custom_metadata_attributes, inverse_of: :custom_metadata_type, dependent: :destroy

  validates :title, presence: true
  validates :custom_metadata_attributes, presence: true
  validates :supported_type, presence: true
  validate :supported_type_must_be_valid_type
  validate :unique_titles_for_custom_metadata_attributes

  alias_method :metadata_attributes, :custom_metadata_attributes

  def attribute_by_title(title)
    custom_metadata_attributes.where(title: title).first
  end

  def attribute_by_method_name(method_name)
    custom_metadata_attributes.detect { |attr| attr.method_name == method_name }
  end

  def attributes_with_linked_custom_metadata_type
    custom_metadata_attributes.reject {|attr| attr.linked_custom_metadata_type.nil?}
  end

  def supported_type_must_be_valid_type
    return if supported_type.blank? # already convered by presence validation
    return if supported_type == "CustomMetadata"
    unless Seek::Util.lookup_class(supported_type, raise: false)
      errors.add(:supported_type, 'is not a type that can supported custom metadata')
    end
  end

  def unique_titles_for_custom_metadata_attributes
    titles = custom_metadata_attributes.collect(&:title)
    if titles != titles.uniq
      errors.add(:custom_metadata_attributes, 'must have unique titles')
    end
  end
end
