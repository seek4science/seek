class SampleSerializer < BaseSerializer
  attributes :title, :sample_type,
             :sample_type_id, :originating_data_file_id,
             :json_metadata

  has_many :sample_resource_links, include_data:true
  has_many :strains, include_data:true
  has_many :organisms, include_data:true
end
