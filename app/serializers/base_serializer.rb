class BaseSerializer
  include JSONAPI::Serializer

  include ApiHelper
  include RelatedItemsHelper

  def self_link
    #{base_url}//#{type}/#{id}
    "/#{type}/#{id}"
  end

  def base_url
    Seek::Config.site_base_host
  end

  #remove link to object/associated --> "#{self_link}/#{format_name(attribute_name)}"
  def relationship_self_link(attribute_name)
  end

  #remove link to object/related/associated
  def relationship_related_link(attribute_name)
  end

  def meta
    {
        created: object.created_at,
        modified: object.updated_at,
        uuid: object.uuid,
        base_url: base_url
    }
  end
end