class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include PolicyHelper
  include RelatedItemsHelper
  include Rails.application.routes.url_helpers

  attribute :policy, if: :show_policy?

  def policy
    BaseSerializer.convert_policy object.policy
  end

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

  def documents
    associated('Document')
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

  def self.convert_policy policy
    { 'access' => (PolicyHelper::access_type_key policy.access_type),
      'permissions' => (self.permits policy)}
  end

  def self.permits policy
    result = []
    policy.permissions.each do |p|
      result.append ({'resource_type' => p.contributor_type.downcase.pluralize,
                      'resource_id' => p.contributor_id.to_s,
                      'access' => (PolicyHelper::access_type_key p.access_type) } )
    end
    return result
  end

  def show_policy?
    respond_to_manage = object.respond_to?('can_manage?')
    respond_to_policy = object.respond_to?('policy')
    current_user = User.current_user
    can_manage = object.can_manage?(current_user)
    return respond_to_policy && respond_to_manage && can_manage
  end


end
