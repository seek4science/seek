class InstitutionSerializer < AvatarObjSerializer
  include CountryCodes
  attributes :title,
             :country

  attribute :country_code do
    object.country
  end

  attribute :country do
    CountryCodes.country(object.country)
  end

  attributes :city, :address, :web_page

  has_many :people
  has_many :projects
end
