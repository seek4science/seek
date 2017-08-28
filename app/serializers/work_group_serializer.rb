class WorkGroupSerializer < BaseSerializer
  attributes :name, :institution, :project

  BaseSerializer.rels(WorkGroup, WorkGroupSerializer)
end
