json.labels @labels
json.datasets do
  json.array! @datasets do |type, data|
    json.label type.name.humanize
    json.backgroundColor ISAHelper::FILL_COLOURS[type.name]
    json.data data
  end
end
