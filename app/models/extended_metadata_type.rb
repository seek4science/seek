class ExtendedMetadataType < ApplicationRecord
  include Seek::Stats::ActivityCounts

  has_many :extended_metadata_attributes, inverse_of: :extended_metadata_type, dependent: :destroy
  has_many :extended_metadatas, inverse_of: :extended_metadata_type
  validates :title, presence: true
  validates :extended_metadata_attributes, presence: true
  validates :supported_type, presence: true
  validate :unique_titles_for_extended_metadata_attributes
  validate :cannot_disable_nested_extended_metadata
  validate :supports_extended_metadata

  alias_method :metadata_attributes, :extended_metadata_attributes

  accepts_nested_attributes_for :extended_metadata_attributes, allow_destroy: true

  scope :enabled, ->{ where(enabled: true) }
  scope :disabled, ->{ where(enabled: false) }

  # built in type
  MIAPPE_TITLE = 'MIAPPE metadata v1.1'.freeze

  def attribute_by_title(title)
    extended_metadata_attributes.where(title: title).first
  end

  def attribute_by_method_name(method_name)
    extended_metadata_attributes.detect { |attr| attr.method_name == method_name }
  end

  def attributes_with_linked_extended_metadata_type
    extended_metadata_attributes.reject {|attr| attr.linked_extended_metadata_type.nil?}
  end

  def extended_type?
    supported_type == 'ExtendedMetadata'
  end

  def linked_metadata_attributes
    ExtendedMetadataAttribute.where(linked_extended_metadata_type_id: id)
  end


  def unique_titles_for_extended_metadata_attributes
    titles = extended_metadata_attributes.collect(&:title)
    if titles != titles.uniq
      errors.add(:extended_metadata_attributes, 'must have unique titles')
    end
  end

  def cannot_disable_nested_extended_metadata
    if !enabled && extended_type?
      errors.add(:enabled, 'cannot be set to false if it is an extended_type used for nested types')
    end
  end

  def supports_extended_metadata
    begin
      unless Seek::Util.lookup_class(self.supported_type).supports_extended_metadata?
        errors.add(:supported_type, " '#{self.supported_type}' does not support extended metadata!")
      end
    rescue NameError
      errors.add(:supported_type, "'#{self.supported_type}' is not a valid support type!")
    end
  end

  # collects all the attributes, including those associated through an attribute with a linked_extended_metadata_type
  def deep_extended_metadata_attributes(extended_metadata_type = self)
    attributes = extended_metadata_type.extended_metadata_attributes.collect do |attr|
      if attr.linked_extended_metadata_type
        deep_extended_metadata_attributes(attr.linked_extended_metadata_type)
      else
        attr
      end
    end
    attributes.flatten
  end

  def usage
    extended_metadatas.count
  end

  def disabled_but_used?
    !enabled && usage > 0
  end

  def self.disabled_but_in_use
    disabled.select{|emt| emt.disabled_but_used?}
  end

end
