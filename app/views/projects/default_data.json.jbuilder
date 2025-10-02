# Doing this using jbuilder so I can use the helper method `policy_hash`
json.policy policy_hash(@project.default_policy, []) if @project.default_policy
json.license @project.default_license if @project.default_license
disciplines = @project.discipline_annotation_labels
json.disciplines disciplines if disciplines.present?
