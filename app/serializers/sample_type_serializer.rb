class SampleTypeSerializer < BaseSerializer
  attributes :title, :description

  attribute :tags do
    serialize_annotations(object)
  end

  has_many :projects
  has_many :samples
end
