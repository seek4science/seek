class ExtendedMetadataTypeSerializer < BaseSerializer
  attributes :title, :supported_type,:enabled
  attribute :extended_metadata_attributes

  def extended_metadata_attributes
    object.extended_metadata_attributes.collect do |attribute|
      get_extended_metadata_attribute(attribute)
    end
  end

  def get_extended_metadata_attribute(attribute)
    {
      "id": attribute.id.to_s,
      "title": attribute.title,
      "label": attribute.label,
      "pid": attribute.pid,
      "description":attribute.description,
      "sample_attribute_type": get_sample_attribute_type(attribute),
      "required": attribute.required,
      "pos": attribute.pos,
      "allow_free_text": attribute.allow_cv_free_text,
      "sample_controlled_vocab_id": attribute.sample_controlled_vocab_id&.to_s,
      "linked_extended_metadata_type_id": attribute.linked_extended_metadata_type_id&.to_s
    }
  end

  def get_sample_attribute_type(attribute)
    SampleAttributeTypeSerializer.new(attribute.sample_attribute_type).to_h
  end
end
