class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include PolicyHelper
  include RelatedItemsHelper
  include Rails.application.routes.url_helpers

  # attribute :policy, if: :show_policy?
  #
  # def policy
  #   convert_policy object.policy
  # end

  def associated(name)
    unless @associated[name].blank?
      items = @associated[name][:items]
      items = items.sort_by(&:id) unless items.blank?
      items
    end
  end

  def people
    associated('Person')
   end

  def projects
    associated('Project')
  end

  def institutions
    associated('Institution')
  end

  def investigations
    associated('Investigation')
  end

  def studies
    associated('Study')
   end

  def assays
    associated('Assay')
  end

  def data_files
    associated('DataFile')
  end

  def models
    associated('Model')
  end

  def sops
    associated('Sop')
  end

  def publications
    associated('Publication')
  end

  def presentations
    associated('Presentation')
  end

  def events
    associated('Event')
  end

  def self_link
    polymorphic_path(object)
  end

  def _links
    { self: self_link }
  end

  # avoid dash-erizing attribute names
  def format_name(attribute_name)
    attribute_name.to_s
  end

  def _meta
    meta = super
    meta[:uuid] = object.uuid if object.respond_to?('uuid')
    meta[:base_url] = base_url
    meta
  end

  def initialize(object, options = {})
    super

    # access related resources with proper authorization & ignore version subclass
    @associated = if object.class.to_s.include?('::Version')
                    associated_resources(object.parent)
                  else
                    associated_resources(object)
                  end
  end

  # def convert_policy policy
  #   { 'access' => (access_type_key policy.access_type),
  #     'permissions' => (permits policy)}
  # end
  #
  # def permits policy
  #   result = []
  #   policy.permissions.each do |p|
  #     result.append ({'resource_type' => p.contributor_type.downcase.pluralize,
  #                     'resource_id' => p.contributor_id,
  #                     'access' => (access_type_key p.access_type) } )
  #   end
  #   return result
  # end

  def administerable?
    answer = false
    begin
      answer = object.can_be_administered_by?(User.current_user)
    rescue
    end
    return answer
  end

  # def show_policy?
  #   return object.respond_to?('policy') && object.respond_to?('can_manage?') && object.can_manage?(User.current_user)
  # end


end
