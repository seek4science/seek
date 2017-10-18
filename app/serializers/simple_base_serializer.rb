class SimpleBaseSerializer < ActiveModel::Serializer
  def type
    object.class.name.demodulize.tableize
  end

  # def self_link
  #   #{base_url}//#{type}/#{id}
  #   "/#{type}/#{id}"
  # end

  def base_url
    Seek::Config.site_base_host
  end

  #remove link to object/associated --> "#{self_link}/#{format_name(attribute_name)}"
  def relationship_self_link(attribute_name)
  end

  #remove link to object/related/associated
  def relationship_related_link(attribute_name)
  end

  def _meta
    meta = if object.respond_to?(:created_at)
      created = object.created_at
      updated = object.updated_at
      {
          created: created || "",
          modified: updated || ""
      }
    else
      {}
           end
    meta[:api_version] = ActiveModel::Serializer.config.api_version
    meta
  end

  def serialize_annotations(object, context=nil)
    tags = []
    object.annotations.each do |tag|
      if (context.nil? || tag.annotation_attribute.name==context)
        tags.append(tag.value.text)
      end
    end
    tags
  end

  def attributes(*args)
    hash = super
    hash.each do |key, value|
      hash[key] = value.presence
    end
    hash
  end

  # def serializable_hash(adapter_options = nil, options = {}, adapter_instance = self.class.serialization_adapter_instance)
  #   hash = super
  #   hash.each do |key, value|
  #     hash[key] = value.presence
  #   end
  #   hash
  # end

  def to_json(options = {})
    super
  end
end