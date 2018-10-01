json.labels @labels
json.datasets do
  json.array! @datasets do |type, data|
    json.label t(type.name.underscore)
    json.backgroundColor ISAHelper::FILL_COLOURS[type.name]
    json.data data
  end
end
