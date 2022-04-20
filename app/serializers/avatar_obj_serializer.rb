class AvatarObjSerializer < BaseSerializer
  attribute :avatar do
    polymorphic_path([object, object.avatar]) unless object.avatar.nil?
  end
end
