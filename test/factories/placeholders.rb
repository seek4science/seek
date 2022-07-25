# Placeholder
Factory.define(:placeholder) do |f|
  f.with_project_contributor
  f.sequence(:title) { |n| "A Placeholder #{n}" }

  f.after_build do |placeholder|
    placeholder.projects = [placeholder.contributor.projects.first] if placeholder.projects.empty?
  end

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
  f.assays { [Factory(:public_assay)] }
  f.other_creators 'Blogs, Joe'
  f.assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  f.file_template { Factory(:public_file_template) }
  f.data_file { Factory(:public_data_file) }

  f.after_create do |placeholder|
    placeholder.annotate_with(['Placeholder-tag1', 'Placeholder-tag2', 'Placeholder-tag3', 'Placeholder-tag4', 'Placeholder-tag5'], 'tag', placeholder.contributor)
    placeholder.save!
  end
end
