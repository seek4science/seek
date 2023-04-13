class CustomMetadataTypeSerializer < BaseSerializer
  attributes :title, :supported_type
  attribute :custom_metadata_attributes

  def custom_metadata_attributes
    object.custom_metadata_attributes.collect do |attribute|
      get_custom_metadata_attribute(attribute)
    end
  end

  def get_custom_metadata_attribute(attribute)
    {
      "id": attribute.id.to_s,
      "title": attribute.title,
      "label": attribute.label,
      "description":attribute.description,
      "sample_attribute_type": get_sample_attribute_type(attribute),
      "required": attribute.required,
      "pos": attribute.pos,
      "sample_controlled_vocab_id": attribute.sample_controlled_vocab_id.nil? ? nil : attribute.sample_controlled_vocab_id.to_s
    }
  end

  def get_sample_attribute_type(attribute)
    SampleAttributeTypeSerializer.new(attribute.sample_attribute_type).to_h
  end
end
