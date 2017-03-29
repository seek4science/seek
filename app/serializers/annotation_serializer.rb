class AnnotationSerializer
  include JSONAPI::Serializer
  attribute :name do
    object.attribute.name
  end
  attribute :value do
    object.value.text
  end
end