# Document
Factory.define(:document) do |f|
  f.title 'This Document'
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person

  f.after_create do |document|
    if document.content_blob.blank?
      document.content_blob = Factory.create(:content_blob, content_type: 'application/pdf',
                                             asset: document, asset_version: document.version)
    else
      document.content_blob.asset = document
      document.content_blob.asset_version = document.version
      document.content_blob.save
    end
  end
end

Factory.define(:min_document, class: Document) do |f|
  f.title 'A Minimal Document'
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |document|
    document.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf',
                                           asset: document, asset_version: document.version)
  end
end

Factory.define(:max_document, class: Document) do |f|
  f.title 'A Maximal Document'
  f.description 'The important report we did for ~important-milestone~'
  f.projects { [Factory.build(:max_project)] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |document|
    document.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: document, asset_version: document.version)
  end
end
