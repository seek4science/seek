class AvatarObjSerializer < BaseSerializer
  attribute :avatar do
    uri = nil
    uri = "/#{object.class.name.pluralize.underscore}/#{object.id}/avatars/#{object.avatar.id}" unless object.avatar.nil?
    uri
  end
end
