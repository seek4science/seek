class SampleTypeSerializer < BaseSerializer
  attributes :title, :description
  attribute :attribute_map

  attribute :tags do
    serialize_annotations(object)
  end

  def attribute_map
    Hash[ object.sample_attributes.collect do |attribute|
       [ attribute.title, SampleAttributeType.find(attribute.sample_attribute_type_id).title]
     end]

  end

  has_many :projects
  has_many :samples
end
