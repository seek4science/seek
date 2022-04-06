class AvatarObjSerializer < BaseSerializer
  attribute :avatar do
    uri = nil
    # This will need to be replaced, possibly with polymorphic_path(object,avatar) once #946 issue is merged
    uri = "/#{object.class.name.pluralize.underscore}/#{object.id}/avatars/#{object.avatar.id}" unless object.avatar.nil?
    uri
  end
end
