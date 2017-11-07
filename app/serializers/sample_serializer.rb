class SampleSerializer < BaseSerializer
  attributes :title, :sample_type,
             :sample_type_id, :originating_data_file_id,
             :json_metadata

  has_many :sample_resource_links, include_data: true
  has_many :strains, include_data: true
  has_many :organisms, include_data: true

  has_many :people
  has_many :projects
  has_many :investigations
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :publications
  has_many :strains
  has_many :samples
end
