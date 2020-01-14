class CustomMetadata < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type

  before_validation :update_json_metadata

  validates_with CustomMetadataValidator

  delegate :custom_metadata_attributes, to: :custom_metadata_type

  def get_attribute_value(attr)
    attr = attr.accessor_name if attr.is_a?(CustomMetadataAttribute)

    data[attr.to_s]
  end

  def set_attribute_value(attr, value)
    attr = attr.accessor_name if attr.is_a?(CustomMetadataAttribute)

    data[attr] = value
  end

  def data=(hash)
    @data = HashWithIndifferentAccess.new(hash)
  end

  def data
    @data ||= build_json_hash
  end

  def blank_attribute?(attr)
    attr = attr.accessor_name if attr.is_a?(CustomMetadataAttribute)

    data[attr].blank? || (data[attr].is_a?(Hash) && data[attr]['id'].blank?)
  end

  def build_json_hash
    if json_metadata
      JSON.parse(json_metadata)
    else
      HashWithIndifferentAccess[custom_metadata_attributes.map { |attr| [attr.title, nil] }]
    end
  end

  def update_json_metadata
    self.json_metadata = data.to_json
  end

  def respond_to_missing?(method_name, include_private = false)
    name = method_name.to_s
    if name.start_with?(CustomMetadataAttribute::METHOD_PREFIX) &&
       data.key?(name.sub(CustomMetadataAttribute::METHOD_PREFIX, '').chomp('='))
      true
    else
      super
    end
  end

  def method_missing(method_name, *args)
    name = method_name.to_s
    if name.start_with?(CustomMetadataAttribute::METHOD_PREFIX)
      setter = name.end_with?('=')
      attribute_name = name.sub(CustomMetadataAttribute::METHOD_PREFIX, '').chomp('=')
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
