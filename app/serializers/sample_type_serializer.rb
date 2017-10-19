class SampleTypeSerializer < BaseSerializer
  attributes :title, :description, :uploaded_template

  has_many :samples, include_data: true
  attribute :sample_attributes # , include_data:true
  has_many :linked_sample_attributes, include_data: true

  attribute :tags do
    serialize_annotations(object)
  end

  has_many :projects
  has_many :samples
end
