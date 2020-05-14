class SampleTypeSerializer < BaseSerializer
  attributes :title, :description
  attribute :attribute_map

  attribute :tags do
    serialize_annotations(object)
  end

  def attribute_map
     object.sample_attributes.collect do |attribute|
       get_sample_attribute(attribute)
         #attribute
    end
  end

  has_many :projects
  has_many :samples

  def get_sample_attribute(attribute)
    {
        "id": attribute.id,
        "title": attribute.title,
        "sample_attibute_type": get_sample_attribute_type(attribute),
        "required": attribute.required,
        "pos": attribute.pos,
        "unit_id": attribute.unit_id.nil? ? nil : Unit.find(attribute.unit_id).symbol,
        "is_title": attribute.is_title,
        "accessor_name": attribute.accessor_name,
        "sample_controlled_vocab_id": attribute.sample_controlled_vocab_id,
        "linked_sample_type_id": attribute.linked_sample_type_id

    }
  end

  def get_sample_attribute_type(attribute)
    attribute_type= SampleAttributeType.find(attribute.sample_attribute_type_id)
    {
        "id": attribute_type.id,
        "title": attribute_type.title,
        "base_type": attribute_type.base_type,
        "regular_expression": attribute_type.regexp,
        "placeholder":attribute_type.placeholder,
        "resolution": attribute_type.resolution
    }
  end
end

