class ServiceSerializer < BaseSerializer
  attributes :title, :description

  has_one :facility

  attribute :tags do
    serialize_annotations(object, context ='tag')
  end

end
