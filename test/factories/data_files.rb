FactoryBot.define do
  # DataFile
  factory(:data_file) do
    with_project_contributor
    sequence(:title) { |n| "A Data File_#{n}" }
  
    after(:create) do |data_file|
      if data_file.content_blob.blank?
        data_file.content_blob = FactoryBot.create(:pdf_content_blob, asset: data_file, asset_version: data_file.version)
      else
        data_file.content_blob.asset = data_file
        data_file.content_blob.asset_version = data_file.version
        data_file.content_blob.save
      end
    end
  end
  
  factory(:public_data_file, parent: :data_file) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:min_data_file, class: DataFile) do
    with_project_contributor
    title { 'A Minimal DataFile' }
    projects { [FactoryBot.create(:min_project)] }
    after(:create) do |data_file|
      data_file.content_blob = FactoryBot.create(:pdf_content_blob, asset: data_file, asset_version: data_file.version)
    end
  end
  
  factory(:max_data_file, class: DataFile) do
    with_project_contributor
    title { 'A Maximal DataFile' }
    description { 'Results - Sampling conformations of ATP-Mg inside the binding pocket' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    assays { [FactoryBot.create(:public_assay)] }
    events {[FactoryBot.build(:event, policy: FactoryBot.create(:public_policy))]}
    workflows {[FactoryBot.build(:workflow, policy: FactoryBot.create(:public_policy))]}
    relationships {[FactoryBot.create(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication))]}
    after(:create) do |data_file|
      if data_file.content_blob.blank?
        data_file.content_blob = FactoryBot.create(:pdf_content_blob, asset: data_file, asset_version: data_file.version)
      end
  
      # required for annotations
      FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
      FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
  
      User.with_current_user(data_file.contributor.user) do
        data_file.tags = ['DataFile-tag1', 'DataFile-tag2', 'DataFile-tag3', 'DataFile-tag4', 'DataFile-tag5']
        data_file.data_type_annotations = 'Sequence features metadata'
        data_file.data_format_annotations = 'JSON'
      end
      data_file.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:rightfield_datafile, parent: :data_file) do
    association :content_blob, factory: :rightfield_content_blob
  end
  
  factory(:blank_rightfield_master_template_data_file, parent: :data_file) do
    association :content_blob, factory: :blank_rightfield_master_template
  end
  
  
  factory(:rightfield_annotated_datafile, parent: :data_file) do
    association :content_blob, factory: :rightfield_annotated_content_blob
  end
  
  factory(:non_spreadsheet_datafile, parent: :data_file) do
    association :content_blob, factory: :cronwright_model_content_blob
  end
  
  factory(:xlsx_spreadsheet_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_content_blob
  end
  
  factory(:xlsm_spreadsheet_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsm_content_blob
  end
  
  factory(:csv_spreadsheet_datafile, parent: :data_file) do
    association :content_blob, factory: :csv_content_blob
  end
  
  factory(:xlsx_population_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_content_blob
  end
  
  factory(:csv_population_datafile, parent: :data_file) do
    association :content_blob, factory: :csv_population_content_blob
  end
  
  factory(:tsv_population_datafile, parent: :data_file) do
    association :content_blob, factory: :tsv_population_content_blob
  end
  
  factory(:xlsx_population_no_header_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_no_header_content_blob
  end
  
  factory(:xlsx_population_no_study_header_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_no_study_header_content_blob
  end
  
  factory(:xlsx_population_no_investigation_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_no_investigation_content_blob
  end
  
  factory(:xlsx_population_no_study_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_no_study_content_blob
  end
  
  factory(:xlsx_population_just_isa_datafile, parent: :data_file) do
    association :content_blob, factory: :xlsx_population_just_isa
  end
  
  factory(:small_test_spreadsheet_datafile, parent: :data_file) do
    association :content_blob, factory: :small_test_spreadsheet_content_blob
  end
  
  factory(:strain_sample_data_file, parent: :data_file) do
    association :content_blob, factory: :strain_sample_data_content_blob
  end
  
  factory(:jerm_data_file, class: DataFile) do
    sequence(:title) { |n| "A Data File_#{n}" }
    contributor { nil }
    projects { [FactoryBot.create(:project)] }
    association :content_blob, factory: :url_content_blob
  
    after(:create) do |data_file|
      if data_file.content_blob.blank?
        data_file.content_blob = FactoryBot.create(:pdf_content_blob, asset: data_file, asset_version: data_file.version)
      else
        data_file.content_blob.asset = data_file
        data_file.content_blob.asset_version = data_file.version
        data_file.content_blob.save
      end
    end
  end
  
  factory(:subscribable, parent: :data_file) {}
  
  # DataFile::Version
  factory(:data_file_version, class: DataFile::Version) do
    association :data_file
    projects { data_file.projects }
    after(:create) do |data_file_version|
      data_file_version.data_file.version += 1
      data_file_version.data_file.save
      data_file_version.version = data_file_version.data_file.version
      data_file_version.title = data_file_version.data_file.title
      data_file_version.save
    end
  end
  
  factory(:data_file_version_with_blob, parent: :data_file_version) do
    after(:create) do |data_file_version|
      if data_file_version.content_blob.blank?
        FactoryBot.create(:pdf_content_blob,
                       asset: data_file_version.data_file,
                       asset_version: data_file_version.version)
      else
        data_file_version.content_blob.asset = data_file_version.data_file
        data_file_version.content_blob.asset_version = data_file_version.version
        data_file_version.content_blob.save
      end
    end
  end
  
  factory(:api_pdf_data_file, parent: :data_file) do
    association :content_blob, factory: :blank_pdf_content_blob
  end
  
  factory(:api_txt_data_file, parent: :data_file) do
    association :content_blob, factory: :blank_txt_content_blob
  end
end
