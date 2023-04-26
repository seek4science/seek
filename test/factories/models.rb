FactoryBot.define do
  # ModelFormat
  factory(:model_format) do
    sequence(:title) { |n| "format #{n}" }
  end
  
  # Model
  factory(:model) do
    sequence(:title) { |n| "A Model #{n}" }
    with_project_contributor
  
    after_create do |model|
      model.content_blobs = [Factory.create(:cronwright_model_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:public_model, parent: :model) do
    policy { Factory(:downloadable_public_policy) }
  end
  
  factory(:min_model, class: Model) do
    with_project_contributor
    title { 'A Minimal Model' }
    projects { [Factory(:min_project)] }
    after_create do |model|
      model.content_blobs = [Factory.create(:non_sbml_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:max_model, class: Model) do
    with_project_contributor
    title { 'A Maximal Model' }
    description { 'Hidden Markov Model' }
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    assays { [Factory(:public_assay)] }
    relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
    organism {Factory.create(:min_organism)}
    model_type { ModelType.find_or_initialize_by(title: 'Ordinary differential equations (ODE)') }
    recommended_environment { RecommendedModelEnvironment.find_or_initialize_by(title: 'JWS Online') }
    after_create do |model|
      model.content_blobs = [Factory.create(:cronwright_model_content_blob,
                                            asset: model, asset_version: model.version),
                             Factory.create(:rightfield_content_blob,
                                            asset: model,
                                            asset_version: model.version)] if model.content_blobs.blank?
      model.annotate_with(['Model-tag1', 'Model-tag2', 'Model-tag3', 'Model-tag4', 'Model-tag5'], 'tag', model.contributor)
      model.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:model_2_files, parent: :model) do
    after_build do |model|
      model.content_blobs = [Factory.create(:cronwright_model_content_blob, asset: model, asset_version: model.version),
                             Factory.create(:rightfield_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:model_2_remote_files, parent: :model) do
  
    after_build do |model|
      model.content_blobs = [Factory.create(:url_content_blob,
                                            asset: model,
                                            asset_version: model.version),
                             Factory.create(:url_content_blob,
                                            asset: model,
                                            asset_version: model.version)] if model.content_blobs.blank?
    end
  end
  
  factory(:model_with_image, parent: :model) do
    sequence(:title) { |n| "A Model with image #{n}" }
    after_create do |model|
      model.model_image = Factory(:model_image, model: model)
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
    after_create do |model|
      model.content_blobs = [Factory.create(:teusink_model_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:xgmml_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:xgmml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:teusink_jws_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:teusink_jws_model_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:non_sbml_xml_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:non_sbml_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:invalid_sbml_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:invalid_sbml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:typeless_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:typeless_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:doc_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:doc_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  factory(:api_model, parent: :model) do
    after_create do |model|
      model.content_blobs = [Factory.create(:blank_pdf_content_blob, asset: model, asset_version: model.version),
                             Factory.create(:blank_xml_content_blob, asset: model, asset_version: model.version)]
    end
  end
  
  # Model::Version
  factory(:model_version, class: Model::Version) do
    association :model
    projects { model.projects }
    after_create do |model_version|
      model_version.model.version += 1
      model_version.model.save
      model_version.version = model_version.model.version
      model_version.title = model_version.model.title
      model_version.save
    end
  end
  
  factory(:model_version_with_blob, parent: :model_version) do
    after_create do |model_version|
      if model_version.content_blobs.empty?
        Factory.create(:teusink_model_content_blob,
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
