class ServiceSerializer < BaseSerializer
  attributes :title, :description

  has_many :investigations
  has_one :facility

end
