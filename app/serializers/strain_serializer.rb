class StrainSerializer < BaseSerializer
  attributes :id, :title, :organism, :description,
             :synonym, :genotype_info, :phenotype_info,
             :provider_name, :provider_id
end
