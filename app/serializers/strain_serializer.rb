class StrainSerializer < BaseSerializer
  attributes :title, :provider_name, :provider_id, :project_ids, :comment,
             :synonym, :genotype_info, :phenotype_info

  attribute :organism do
    {
        organism_id: object.organism.id.to_s,
        title: object.organism.title
    }
  end
end
