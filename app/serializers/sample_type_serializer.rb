class SampleTypeSerializer < BaseSerializer
  attributes :title, :description
  attribute :attribute_map

  attribute :tags do
    serialize_annotations(object)
  end

  def attribute_map
     object.sample_attributes.collect do |attribute|
       get_sample_attribute(attribute)
    end
  end

  has_many :projects
  has_many :samples
  has_many :submitter
  has_many :assays

  def get_sample_attribute(attribute)
    {
        "id": attribute.id.to_s,
        "title": attribute.title,
        "sample_attribute_type": get_sample_attribute_type(attribute),
        "required": attribute.required,
        "pos": attribute.pos.to_s,
        "unit": attribute.unit_id.nil? ? nil : Unit.find(attribute.unit_id).symbol,
        "is_title": attribute.is_title,
        "sample_controlled_vocab_id": attribute.sample_controlled_vocab_id.nil? ? nil : attribute.sample_controlled_vocab_id.to_s,
        "linked_sample_type_id": attribute.linked_sample_type_id.nil? ? nil : attribute.linked_sample_type_id.to_s
    }
  end

  def get_sample_attribute_type(attribute)
    attribute_type= SampleAttributeType.find(attribute.sample_attribute_type_id)
    {
        "id": attribute_type.id.to_s,
        "title": attribute_type.title,
        "base_type": attribute_type.base_type,
        "regular_expression": attribute_type.regexp,
        "placeholder":attribute_type.placeholder,
        "resolution": attribute_type.resolution
    }
  end
end

