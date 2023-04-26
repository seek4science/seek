FactoryBot.define do
  # File template
  factory(:file_template) do
    title 'This FileTemplate'
    association :contributor, factory: :person
  
    after_build do |file_template|
      file_template.projects = [file_template.contributor.projects.first] if file_template.projects.empty?
    end
  
    after_create do |file_template|
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
  
  factory(:public_file_template, parent: :file_template) do
    policy { Factory(:downloadable_public_policy) }
  end
  
  factory(:private_file_template, parent: :file_template) do
    policy { Factory(:private_policy) }
  end
  
  factory(:min_file_template, class: FileTemplate) do
    with_project_contributor
    title 'A Minimal FileTemplate'
    policy { Factory(:downloadable_public_policy) }
    after_create do |ft|
      ft.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf',
                                             asset: ft, asset_version: ft.version)
    end
  end
  
  factory(:max_file_template, class: FileTemplate) do
    with_project_contributor
    title 'A Maximal FileTemplate'
    description 'The important report we did for ~important-milestone~'
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    policy { Factory(:downloadable_public_policy) }
    assays { [Factory(:public_assay)] }
    after_create do |ft|
      ft.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: ft, asset_version: ft.version)
      ft.annotate_with(['FileTemplate-tag1', 'FileTemplate-tag2', 'FileTemplate-tag3', 'FileTemplate-tag4', 'FileTemplate-tag5'], 'tag', ft.contributor)
  
      # required for annotations
      Factory(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
      Factory(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
  
      User.with_current_user(ft.contributor.user) do
        ft.data_type_annotations = 'Sequence features metadata'
        ft.data_format_annotations = 'JSON'
      end
      ft.save!
    end
    other_creators 'Blogs, Joe'
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  # Factory::Version
  factory(:file_template_version, class: FileTemplate::Version) do
    association :file_template
    projects { file_template.projects }
    after_create do |file_template_version|
      file_template_version.file_template.version += 1
      file_template_version.file_template.save
      file_template_version.version = file_template_version.file_template.version
      file_template_version.title = file_template_version.file_template.title
      file_template_version.save
    end
  end
  
  factory(:api_pdf_file_template, parent: :file_template) do
    association :content_blob, factory: :blank_pdf_content_blob
  end
  
end
