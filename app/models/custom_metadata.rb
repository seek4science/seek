class CustomMetadata < ApplicationRecord
  include Seek::JSONMetadata::Serialization

  belongs_to :item, polymorphic: true
  belongs_to :custom_metadata_type, validate: true

  validates_with CustomMetadataValidator

  delegate :custom_metadata_attributes, to: :custom_metadata_type

  # for polymorphic behaviour with sample
  alias_method :metadata_type, :custom_metadata_type

  def custom_metadata_type=(type)
    super
    @data = Seek::JSONMetadata::Data.new(type)
    update_json_metadata
    type
  end

  def attribute_class
    CustomMetadataAttribute
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
