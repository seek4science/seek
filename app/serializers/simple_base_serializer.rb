class SimpleBaseSerializer < ActiveModel::Serializer
  def type
    object.class.name.demodulize.tableize
  end

  def base_url
    Seek::Config.site_base_host
  end

  # remove link to object/associated --> "#{self_link}/#{format_name(attribute_name)}"
  def relationship_self_link(attribute_name); end

  # remove link to object/related/associated
  def relationship_related_link(attribute_name); end

  def _meta
    item = meta_item
    meta = if item.respond_to?(:created_at)
      created = item.created_at
      updated = item.updated_at
      {
        created: created || '',
        modified: updated || ''
      }
    else
      {}
    end
    meta[:api_version] = ActiveModel::Serializer.config.api_version
    meta[:base_url] = base_url
    meta[:uuid] = item.uuid if item.respond_to?('uuid')
    meta[:user_access] = current_user_permissions if item.try(:authorization_supported?)
    meta
  end

  # the item described by the meta block, which can differ from the object being serialized
  def meta_item
    object
  end

  # what the user making the request is allowed to do with the item
  def current_user_permissions
    Seek::Permissions::ActsAsAuthorized::AUTHORIZATION_ACTIONS.index_with do |action|
      !!meta_item.can_perform?(action, User.current_user)
    end
  end

  def serialize_annotations(object, context = nil)
    tags = []
    object.annotations.each do |tag|
      if context.nil? || tag.annotation_attribute.name == context
        tags.append(tag.value.text)
      end
    end
    tags.sort!
    tags
  end
end
