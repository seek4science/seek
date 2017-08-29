# json.api_format! @institution
# #json.api_format! Person.all[2] #works
#
#  associated_resources_json(json, @institution)
#
# # associated = get_related_resources(@institution)
# # associated.each_value do |value|
# #   if (value[:items] != [])
# #     json.api_format! value[:items]
# #   end
# # end
#
# #json.api_format! associated["Project"][:items]
# #json.api_format! associated["Person"][:items]
