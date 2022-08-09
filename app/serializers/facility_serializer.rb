class FacilitySerializer < BaseSerializer
  attributes :title, :description

  has_many :institutions
  has_many :services

end
