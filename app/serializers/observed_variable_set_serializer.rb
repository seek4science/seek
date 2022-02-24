class ObservedVariableSetSerializer < ActiveModel::Serializer
  attributes :id, :title, :contributor_id, :project_ids
end
