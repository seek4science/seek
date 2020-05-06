class SampleSerializer < PCSSerializer

  attribute :json_metadata
  
  attribute :tags do
    serialize_annotations(object)
  end

  has_many :projects
  has_one :sample_type
end
 
