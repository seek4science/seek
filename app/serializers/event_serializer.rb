class EventSerializer < BaseSerializer
  attributes :id, :title, :description, :url,
             :address, :city, :country,
             :start_date, :end_date

end
