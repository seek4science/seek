class InstitutionSerializer < AvatarObjSerializer
  include CountryCodes
  attributes :title,
             :country

  attribute :country_code do
    CountryCodes.code(object.country)
  end

  attributes :city, :address, :web_page

  has_many :people
  has_many :projects
end
