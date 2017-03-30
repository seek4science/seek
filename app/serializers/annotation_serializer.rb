# to make "tags" inclusion possible for objects in the json output format
class AnnotationSerializer < SimpleBaseSerializer
  #include JSONAPI::Serializer
  attribute :name do
    object.attribute.name
  end
  attribute :value do
    object.value.text
  end
  def self_link
  end
end