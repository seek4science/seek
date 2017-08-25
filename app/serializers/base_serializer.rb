class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper

  has_many :assays, include_data:true do
    @associated["Assay"][:items]
  end
  has_many :data_files, include_data:true do
    @associated["DataFile"][:items]
  end
  has_many :events, include_data:true do
    @associated["Event"][:items]
  end
  has_many :investigations, include_data:true do
    @associated["Investigation"][:items]
  end
  has_many :institutions, include_data:true do
    @associated["Institution"][:items]
  end
  has_many :models, include_data:true do
    @associated["Model"][:items]
  end
  has_many :people, include_data:true  do
    @associated["Person"][:items]
  end
  has_many :presentations, include_data:true do
    @associated["Presentation"][:items]
  end
  has_many :projects, include_data:true do
    @associated["Project"][:items]
  end
  has_many :publications, include_data:true do
    @associated["Publication"][:items]
  end
  has_many :samples, include_data:true do
    @associated["Sample"][:items]
  end
  has_many :sops, include_data:true do
    @associated["Sop"][:items]
  end
  has_many :studies, include_data:true do
    @associated["Study"][:items]
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

  def initialize(object, options = {})
    super
    @associated = associated_resources(object)
  end
end