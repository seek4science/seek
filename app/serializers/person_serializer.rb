require 'digest/sha1'
class PersonSerializer < AvatarObjSerializer
  attributes :title, :description,
             :first_name, :last_name, :orcid,
             :mbox_sha1sum

  attribute :expertise do
    serialize_annotations(object, context = 'expertise')
  end
  attribute :tools do
    serialize_annotations(object, context = 'tool')
  end

  attribute :orcid do
    object.orcid_uri
  end

  attribute :login, if: -> { User.current_user&.is_admin? } do
    object&.user&.login
  end

  include_related_items
end
