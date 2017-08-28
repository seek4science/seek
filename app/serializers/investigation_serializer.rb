class InvestigationSerializer < PCSSerializer
  attributes :title, :description

  BaseSerializer.rels(Investigation, InvestigationSerializer)
end
