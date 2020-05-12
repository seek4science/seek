class SampleTypeSerializer < BaseSerializer
  attributes :title, :description, :template_link
  attribute :attribute_map

  attribute :tags do
    serialize_annotations(object)
  end

  def template_link
    "#{base_url}#{download_sample_type_content_blob_path(object,object.template)}"
  end


  def attribute_map
     object.sample_attributes.collect do |attribute|
      {attribute.accessor_name => get_sample_attribute_type(attribute)}
    end
  end

  has_many :projects
  has_many :samples


  def get_sample_attribute_type(attribute)
    {
        "required": attribute.required,
        "title": attribute.is_title,
        "type": SampleAttributeType.find(attribute.sample_attribute_type_id).title
    }
  end
end

