class SampleAttributeTypeSerializer < BaseSerializer
  attributes :id, :title, :base_type, :regexp

  def id
    object.id.to_s
  end
end
