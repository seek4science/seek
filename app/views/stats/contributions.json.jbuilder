json.labels @contribution_stats[:labels]
json.datasets do
  json.array! @contribution_stats[:datasets] do |type, data|
    json.label t(type.name.underscore)
    json.backgroundColor ISAHelper::FILL_COLOURS[type.name]
    json.data data
  end
end
