# File template
Factory.define(:file_template) do |f|
  f.title 'This FileTemplate'
  f.association :contributor, factory: :person

  f.after_build do |file_template|
    file_template.projects = [file_template.contributor.projects.first] if file_template.projects.empty?
  end

  f.after_create do |file_template|
    if file_template.content_blob.blank?
      file_template.content_blob = Factory.create(:content_blob, content_type: 'application/pdf',
                                             asset: file_template, asset_version: file_template.version)
    else
      file_template.content_blob.asset = file_template
      file_template.content_blob.asset_version = file_template.version
      file_template.content_blob.save
    end
  end
end

Factory.define(:public_file_template, parent: :file_template) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:private_file_template, parent: :file_template) do |f|
  f.policy { Factory(:private_policy) }
end

Factory.define(:min_file_template, class: FileTemplate) do |f|
  f.with_project_contributor
  f.title 'A Minimal FileTemplate'
  f.policy { Factory(:downloadable_public_policy) }
  f.after_create do |ft|
    ft.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf',
                                           asset: ft, asset_version: ft.version)
  end
end

Factory.define(:max_file_template, class: FileTemplate) do |f|
  f.with_project_contributor
  f.title 'A Maximal FileTemplate'
  f.description 'The important report we did for ~important-milestone~'
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.policy { Factory(:downloadable_public_policy) }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.after_create do |ft|
    ft.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: ft, asset_version: ft.version)
  end
  f.other_creators 'Blogs, Joe'
end

# Factory::Version
Factory.define(:file_template_version, class: FileTemplate::Version) do |f|
  f.association :file_template
  f.projects { file_template.projects }
  f.after_create do |file_template_version|
    file_template_version.file_template.version += 1
    file_template_version.file_template.save
    file_template_version.version = file_template_version.file_template.version
    file_template_version.title = file_template_version.file_template.title
    file_template_version.save
  end
end

Factory.define(:api_pdf_file_template, parent: :file_template) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end

