class BaseSerializer < SimpleBaseSerializer
  include ApiHelper
  include PolicyHelper
  include RelatedItemsHelper
  include Rails.application.routes.url_helpers

  attribute :policy, if: :show_policy?

  def policy
    BaseSerializer.convert_policy object.policy
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

  def BaseSerializer.convert_policy policy
    { 'access' => (PolicyHelper::access_type_key policy.access_type),
      'permissions' => (BaseSerializer.permits policy)}
  end

  def BaseSerializer.permits policy
    policy.permissions.map do |p|
      resource = { id: p.contributor_id.to_s, type: p.contributor_type.underscore.pluralize }

      { resource: resource, access: (PolicyHelper::access_type_key(p.access_type)) }
    end
  end

  def show_policy?
    respond_to_manage = object.respond_to?('can_manage?')
    respond_to_policy = object.respond_to?('policy')
    current_user = User.current_user
    can_manage = object.can_manage?(current_user)
    return respond_to_policy && respond_to_manage && can_manage
  end

  def submitter
    result = determine_submitter object
    if result.blank?
      return []
    else
      return [result]
    end
  end
end
