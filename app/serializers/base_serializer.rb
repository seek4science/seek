class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include RelatedItemsHelper

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

    #access related resources with proper authorization & ignore version subclass
    if (object.class.to_s.include?("::Version"))
      @associated = associated_resources(object.parent)
    else
      @associated = associated_resources(object)
    end
    @associated.each do |k,v|
      unless (v[:items].blank?)
        begin
          self.class.has_many k.pluralize.downcase, include_data:true do
            v[:items]
          end
        end
      end
    end
  end

end
