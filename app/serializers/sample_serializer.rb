class SampleSerializer < PCSSerializer

  attribute :title
  attribute :attribute_map
  
  attribute :tags do
    serialize_annotations(object)
  end

  has_many :projects
  has_one :sample_type
  has_many :submitter
  has_many :creators
  has_many :data_files

  def attribute_map
      Hash[object.sample_type.sample_attributes.collect do |attribute|
        [attribute.title, object.get_attribute_value(attribute)]
      end]
  end

end
 
