# File template
Factory.define(:file_template) do |f|
  f.title 'This File_Template'
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
