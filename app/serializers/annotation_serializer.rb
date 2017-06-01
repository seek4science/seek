# to make "tags" inclusion possible for objects in the json output format
class AnnotationSerializer < SimpleBaseSerializer
  attribute :id
  attribute :value do
     object.value.text
  end
  def self_link
  end
end