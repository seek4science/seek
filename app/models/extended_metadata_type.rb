class ExtendedMetadataType < ApplicationRecord
  has_many :extended_metadata_attributes, inverse_of: :extended_metadata_type, dependent: :destroy

  validates :title, presence: true
  validates :extended_metadata_attributes, presence: true
  validates :supported_type, presence: true
  validate :supported_type_must_be_valid_type
  validate :unique_titles_for_extended_metadata_attributes

  alias_method :metadata_attributes, :extended_metadata_attributes

  def attribute_by_title(title)
    extended_metadata_attributes.where(title: title).first
  end

  def attribute_by_method_name(method_name)
    extended_metadata_attributes.detect { |attr| attr.method_name == method_name }
  end

  def attributes_with_linked_extended_metadata_type
    extended_metadata_attributes.reject {|attr| attr.linked_extended_metadata_type.nil?}
  end

  def supported_type_must_be_valid_type
    return if supported_type.blank? # already convered by presence validation
    unless Seek::Util.lookup_class(supported_type, raise: false)
      errors.add(:supported_type, 'is not a type that can supported extended metadata')
    end
  end

  def unique_titles_for_extended_metadata_attributes
    titles = extended_metadata_attributes.collect(&:title)
    if titles != titles.uniq
      errors.add(:extended_metadata_attributes, 'must have unique titles')
    end
  end
end
