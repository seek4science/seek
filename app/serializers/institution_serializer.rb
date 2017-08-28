class InstitutionSerializer < AvatarObjSerializer
  attributes :title,
             :country, :city, :address,
             :web_page

  BaseSerializer.rels(Institution, InstitutionSerializer)
end

