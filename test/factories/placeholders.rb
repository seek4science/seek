# Placeholder
Factory.define(:placeholder) do |f|
  f.with_project_contributor
  f.sequence(:title) { |n| "A Placeholder #{n}" }
end

Factory.define(:public_placeholder, parent: :placeholder) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:private_placeholder, parent: :placeholder) do |f|
  f.policy { Factory(:private_policy) }
end

Factory.define(:min_placeholder, class: Placeholder) do |f|
  f.with_project_contributor
  f.title 'A Minimal Placeholder'
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:max_placeholder, class: Placeholder) do |f|
  f.with_project_contributor
  f.title 'A Maximal Placeholder'
  f.description 'The Maximal Placeholder'
  f.policy { Factory(:downloadable_public_policy) }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.other_creators 'Blogs, Joe'
end
