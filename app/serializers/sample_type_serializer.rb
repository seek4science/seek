class SampleTypeSerializer < BaseSerializer
  attributes :title, :description
  attribute :sample_attributes

  attribute :tags do
    serialize_annotations(object)
  end

  def sample_attributes
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
      "description": attribute.description,
      "pid": attribute.pid,
      "sample_attribute_type": get_sample_attribute_type(attribute),
      "required": attribute.required,
      "pos": attribute.pos.to_s,
      "unit": attribute.unit.nil? ? nil : attribute.unit.symbol,
      "is_title": attribute.is_title,
      "sample_controlled_vocab_id": attribute.sample_controlled_vocab_id.nil? ? nil : attribute.sample_controlled_vocab_id.to_s,
      "linked_sample_type_id": attribute.linked_sample_type_id.nil? ? nil : attribute.linked_sample_type_id.to_s
    }
  end

  def get_sample_attribute_type(attribute)
    SampleAttributeTypeSerializer.new(attribute.sample_attribute_type).to_h
  end
end
