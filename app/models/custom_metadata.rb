class CustomMetadata < ApplicationRecord
  class InvalidDataException < RuntimeError; end

  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type

  before_validation :update_json_metadata

  validates_with CustomMetadataValidator

  delegate :custom_metadata_attributes, to: :custom_metadata_type

  def get_attribute_value(attr)
    attr = attr.title if attr.is_a?(CustomMetadataAttribute)

    data[attr.to_s]
  end

  def set_attribute_value(attr, value)
    attr = attr.title if attr.is_a?(CustomMetadataAttribute)

    data[attr] = value
  end

  def data=(hash)
    attribute_titles = custom_metadata_attributes.collect(&:title)
    provided_keys = hash.keys.collect(&:to_s)
    wrong = provided_keys - attribute_titles
    if wrong.any?
      raise InvalidDataException,
            'invalid attribute keys in data assignment, must match attribute titles ' \
            "(#{'culprit'.pluralize(wrong.size)} - #{wrong.join(',')}"
    end
    @data = HashWithIndifferentAccess.new(hash)
  end

  def data
    @data ||= build_json_hash
  end

  def blank_attribute?(attr)
    attr = attr.title if attr.is_a?(CustomMetadataAttribute)

    data[attr].blank? || (data[attr].is_a?(Hash) && data[attr]['id'].blank?)
  end

  def build_json_hash
    if json_metadata
      JSON.parse(json_metadata)
    elsif custom_metadata_type
      HashWithIndifferentAccess[custom_metadata_attributes.map { |attr| [attr.title, nil] }]
    else
      {}
    end
  end

  def update_json_metadata
    self.json_metadata = data.to_json
  end

  def respond_to_missing?(method_name, include_private = false)
    name = method_name.to_s
    if custom_metadata_type.try(:attribute_by_method_name, name.chomp('=')).present?
      true
    else
      super
    end
  end

  def method_missing(method_name, *args)
    name = method_name.to_s
    if (attribute = custom_metadata_type.attribute_by_method_name(name.chomp('='))).present?
      setter = name.end_with?('=')
      attribute_name = attribute.title
      if data.key?(attribute_name)
        set_attribute_value(attribute_name, args.first) if setter
        get_attribute_value(attribute_name)
      else
        super
      end
    else
      super
    end
  end
end
