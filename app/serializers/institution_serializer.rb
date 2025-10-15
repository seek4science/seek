class InstitutionSerializer < AvatarObjSerializer
  include CountryCodes

  attribute :title do
    object.base_title
  end

  attributes :department, :ror_id, :country

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
