# ModelFormat
Factory.define(:model_format) do |f|
  f.sequence(:title) { |n| "format #{n}" }
end

# Model
Factory.define(:model) do |f|
  f.sequence(:title) { |n| "A Model #{n}" }
  f.with_project_contributor

  f.after_create do |model|
    model.content_blobs = [Factory.create(:cronwright_model_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
  end
end

Factory.define(:min_model, class: Model) do |f|
  f.with_project_contributor
  f.title 'A Minimal Model'
  f.projects { [Factory.build(:min_project)] }
end

Factory.define(:max_model, class: Model) do |f|
  f.with_project_contributor
  f.title 'A Maximal Model'
  f.description 'Hidden Markov Model'
  f.projects { [Factory.build(:max_project)] }
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.organism {Factory.create(:min_organism)}
  f.after_create do |model|
    model.content_blobs = [Factory.create(:cronwright_model_content_blob,
                                          asset: model, asset_version: model.version),
                           Factory.create(:rightfield_content_blob,
                                          asset: model,
                                          asset_version: model.version)] if model.content_blobs.blank?
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:model_2_files, parent: :model) do |f|
  f.after_build do |model|
    model.content_blobs = [Factory.create(:cronwright_model_content_blob, asset: model, asset_version: model.version),
                           Factory.create(:rightfield_content_blob, asset: model, asset_version: model.version)] if model.content_blobs.blank?
  end
end

Factory.define(:model_2_remote_files, parent: :model) do |f|

  f.after_build do |model|
    model.content_blobs = [Factory.create(:url_content_blob,
                                          asset: model,
                                          asset_version: model.version),
                           Factory.create(:url_content_blob,
                                          asset: model,
                                          asset_version: model.version)] if model.content_blobs.blank?
  end
end

Factory.define(:model_with_image, parent: :model) do |f|
  f.sequence(:title) { |n| "A Model with image #{n}" }
  f.after_create do |model|
    model.model_image = Factory(:model_image, model: model)
  end
end

Factory.define(:model_image) do |f|
  f.original_filename 'file_picture.png'
  f.image_file fixture_file_upload("#{Rails.root}/test/fixtures/files/file_picture.png", 'image/png')
  f.content_type 'image/png'
end

Factory.define(:cronwright_model, parent: :model) do |f|
  f.content_type 'text/xml'
  f.association :content_blob, factory: :cronwright_model_content_blob
  f.original_filename 'cronwright.xml'
end

Factory.define(:teusink_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:teusink_model_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:xgmml_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:xgmml_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:teusink_jws_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:teusink_jws_model_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:non_sbml_xml_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:non_sbml_xml_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:invalid_sbml_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:invalid_sbml_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:typeless_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:typeless_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:doc_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:doc_content_blob, asset: model, asset_version: model.version)]
  end
end

Factory.define(:api_model, parent: :model) do |f|
  f.after_create do |model|
    model.content_blobs = [Factory.create(:blank_pdf_content_blob, asset: model, asset_version: model.version),
                           Factory.create(:blank_xml_content_blob, asset: model, asset_version: model.version)]
  end
end

# Model::Version
Factory.define(:model_version, class: Model::Version) do |f|
  f.association :model
  f.projects { model.projects }
  f.after_create do |model_version|
    model_version.model.version += 1
    model_version.model.save
    model_version.version = model_version.model.version
    model_version.title = model_version.model.title
    model_version.save
  end
end

Factory.define(:model_version_with_blob, parent: :model_version) do |f|
  f.after_create do |model_version|
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
