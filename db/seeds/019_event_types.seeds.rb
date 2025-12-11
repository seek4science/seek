count = EventType.count

event_types = YAML.load_file(File.join(Rails.root, 'config/default_data/', 'event_types.yml')).values

event_types.each do |event_type|
  title = event_type['title']
  description = event_type['description']
  EventType.find_or_create_by!(title: title) do |event_type|
    event_type.description = description
  end
end
change = EventType.count - count
if change.positive?
  puts "Seeded #{change} event types"
end