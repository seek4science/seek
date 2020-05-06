class SampleTypeSerializer < BaseSerializer
  attributes :description

  attribute :tags do
    serialize_annotations(object)
  end

  has_many :projects
end
