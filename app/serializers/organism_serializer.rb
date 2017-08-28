class OrganismSerializer < BaseSerializer
  attribute :title

  BaseSerializer.rels(Organism, OrganismSerializer)
end
