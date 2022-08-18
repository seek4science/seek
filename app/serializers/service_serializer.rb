class ServiceSerializer < BaseSerializer
  attributes :title, :description

  has_one :facility

end
