class FacilitySerializer < BaseSerializer
  include CountryCodes
  attributes :title, :description

  attribute :country_code do
    object.country
  end

  attribute :country do
    CountryCodes.country(object.country)
  end

  attributes :city, :address, :web_page

  has_many :institutions
  has_many :services

end
