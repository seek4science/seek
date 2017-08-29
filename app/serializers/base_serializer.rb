class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper

  has_many :associated, include_data:true do  #--> add this when everything is serialized.
    associated_resources(object) # ||  { "data": [] }
  end

  # def self_link
  #   #{base_url}//#{type}/#{id}
  #   "/#{type}/#{id}"
  # end
  #
  # def base_url
  #   Seek::Config.site_base_host
  # end
  #
  # #remove link to object/associated --> "#{self_link}/#{format_name(attribute_name)}"
  # def relationship_self_link(attribute_name)
  # end
  #
  # #remove link to object/related/associated
  # def relationship_related_link(attribute_name)
  # end

  #avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def meta
    #content-blob doesn't have timestamps
    if object.respond_to?('created_at')
      created = object.created_at
      updated = object.updated_at
    end
    if object.respond_to?('uuid')
      uuid = object.uuid
    end
    {
        created: created || "",
        modified: updated || "",
        uuid: uuid || "",
        base_url: base_url
    }
  end
end