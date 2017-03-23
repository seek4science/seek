class AvatarObjSerializer < BaseSerializer

  attribute :avatar do
    avatar_href_link(object)
  end

end