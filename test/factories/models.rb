FactoryBot.define do
  # ModelFormat
  factory(:model_format) do
    sequence(:title) { |n| "format #{n}" }
  end
  
  # Model
  factory(:model) do
    sequence(:title) { |n| "A Model #{n}" }
    with_project_contributor
  
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:cronwright_model_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:public_model, parent: :model) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:min_model, class: Model) do
    with_project_contributor
    title { 'A Minimal Model' }
    projects { [FactoryBot.create(:min_project)] }
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:non_sbml_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:max_model, class: Model) do
    with_project_contributor
    title { 'A Maximal Model' }
    description { 'Hidden Markov Model' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    assays { [FactoryBot.create(:public_assay)] }
    relationships {[FactoryBot.create(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication))]}
    organism {FactoryBot.create(:min_organism)}
    model_type { ModelType.find_or_initialize_by(title: 'Ordinary differential equations (ODE)') }
    recommended_environment { RecommendedModelEnvironment.find_or_initialize_by(title: 'JWS Online') }
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:cronwright_model_content_blob,
                                            asset: model, asset_version: model.version),
                             FactoryBot.create(:rightfield_content_blob,
                                            asset: model,
                                            asset_version: model.version)] if model.content_blobs.blank?
      model.annotate_with(['Model-tag1', 'Model-tag2', 'Model-tag3', 'Model-tag4', 'Model-tag5'], 'tag', model.contributor)
      model.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:model_2_files, parent: :model) do
    after(:build) do |model|
      model.content_blobs = [FactoryBot.create(:cronwright_model_content_blob, asset: model, asset_version: model.version),
                             FactoryBot.create(:rightfield_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:model_2_remote_files, parent: :model) do
  
    after(:build) do |model|
      model.content_blobs = [FactoryBot.create(:url_content_blob,
                                            asset: model,
                                            asset_version: model.version),
                             FactoryBot.create(:url_content_blob,
                                            asset: model,
                                            asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:model_with_image, parent: :model) do
    sequence(:title) { |n| "A Model with image #{n}" }
    after(:create) do |model|
      model.model_image = FactoryBot.create(:model_image, model: model)
    end
  end
  
  factory(:model_image) do
    original_filename { 'file_picture.png' }
    image_file { fixture_file_upload('file_picture.png', 'image/png') }
    content_type { 'image/png' }
  end
  
  factory(:cronwright_model, parent: :model) do
    content_type { 'text/xml' }
    association :content_blob, factory: :cronwright_model_content_blob
    original_filename { 'cronwright.xml' }
  end
  
  factory(:teusink_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:teusink_model_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:xgmml_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:xgmml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:teusink_jws_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:teusink_jws_model_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:non_sbml_xml_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:non_sbml_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:invalid_sbml_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:invalid_sbml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:typeless_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:typeless_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:doc_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:doc_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:api_model, parent: :model) do
    after(:create) do |model|
      model.content_blobs = [FactoryBot.create(:blank_pdf_content_blob, asset: model, asset_version: model.version),
                             FactoryBot.create(:blank_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end

  factory(:model_with_urls, parent: :model) do |f|
    after(:create) do |model|
      model.content_blobs = [
        FactoryBot.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true),
        FactoryBot.create(:content_blob, url: 'http://webpage2.com', asset: model, asset_version: model.version, external_link: true)
      ]
    end
  end

  factory(:model_with_urls_and_files, parent: :model) do |f|
    after(:create) do |model|
      model.content_blobs = [
        FactoryBot.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true),
        FactoryBot.create(:cronwright_model_content_blob, asset: model, asset_version: model.version)
      ]
    end
  end
  
  # Model::Version
  factory(:model_version, class: Model::Version) do
    association :model
    projects { model.projects }
    after(:create) do |model_version|
      model_version.model.version += 1
      model_version.model.save
      model_version.version = model_version.model.version
      model_version.title = model_version.model.title
      model_version.save
    end
  end
  
  factory(:model_version_with_blob, parent: :model_version) do
    after(:create) do |model_version|
      if model_version.content_blobs.empty?
        FactoryBot.create(:teusink_model_content_blob,
                       asset: model_version.model,
                       asset_version: model_version.model.version)
      else
        model_version.content_blobs.each do |cb|
          cb.asset = model_version.model
          cb.asset_version = model_version.version
          cb.save
        end
      end
    end
  end
end
