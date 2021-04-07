# Placeholder
Factory.define(:placeholder) do |f|
  f.with_project_contributor
  f.sequence(:title) { |n| "A Placeholder #{n}" }
end

