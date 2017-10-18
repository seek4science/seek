class StrainSerializer < BaseSerializer
  attributes :title, :provider_name, :provider_id, :project_ids, :comment,
             :synonym, :genotype_info, :phenotype_info

  has_one :organism
  has_many :projects
  has_many :assays
  has_many :samples
end
