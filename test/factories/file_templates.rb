FactoryBot.define do
  # File template
  factory(:file_template) do
    title { 'This FileTemplate' }
    with_project_contributor
  
    after(:create) do |file_template|
      if file_template.content_blob.blank?
        file_template.content_blob = FactoryBot.create(:content_blob, content_type: 'application/pdf',
                                               asset: file_template, asset_version: file_template.version)
      else
        file_template.content_blob.asset = file_template
        file_template.content_blob.asset_version = file_template.version
        file_template.content_blob.save
      end
    end
  end
  
  factory(:public_file_template, parent: :file_template) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:private_file_template, parent: :file_template) do
    policy { FactoryBot.create(:private_policy) }
  end
  
  factory(:min_file_template, class: FileTemplate) do
    with_project_contributor
    title { 'A Minimal FileTemplate' }
    policy { FactoryBot.create(:downloadable_public_policy) }
    after(:create) do |ft|
      ft.content_blob = FactoryBot.create(:min_content_blob, content_type: 'application/pdf',
                                             asset: ft, asset_version: ft.version)
    end
  end
  
  factory(:max_file_template, class: FileTemplate) do
    with_project_contributor
    title { 'A Maximal FileTemplate' }
    description { 'The important report we did for ~important-milestone~' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    policy { FactoryBot.create(:downloadable_public_policy) }
    assays { [FactoryBot.create(:public_assay)] }
    after(:create) do |ft|
      ft.content_blob = FactoryBot.create(:min_content_blob, content_type: 'application/pdf', asset: ft, asset_version: ft.version)
      ft.annotate_with(['FileTemplate-tag1', 'FileTemplate-tag2', 'FileTemplate-tag3', 'FileTemplate-tag4', 'FileTemplate-tag5'], 'tag', ft.contributor)
  
      # required for annotations
      FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
      FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
  
      User.with_current_user(ft.contributor.user) do
        ft.data_type_annotations = 'Sequence features metadata'
        ft.data_format_annotations = 'JSON'
      end
      ft.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  # FactoryBot::Version
  factory(:file_template_version, class: FileTemplate::Version) do
    association :file_template
    projects { file_template.projects }
    after(:create) do |file_template_version|
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
