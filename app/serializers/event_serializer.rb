class EventSerializer < BaseSerializer
  attributes :title, :description, :url,
             :address, :city, :country,
             :start_date, :end_date

  BaseSerializer.rels(Event, EventSerializer)
end
