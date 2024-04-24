class ObservationUnitSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :text, :identifier, :string, :organism_id, :integer
end
