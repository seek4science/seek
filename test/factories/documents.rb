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

Factory.define(:public_document, parent: :document) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:private_document, parent: :document) do |f|
  f.policy { Factory(:private_policy) }
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

# Factory::Version
Factory.define(:document_version, class: Document::Version) do |f|
  f.association :document
  f.projects { document.projects }
  f.after_create do |document_version|
    document_version.document.version += 1
    document_version.document.save
    document_version.version = document_version.document.version
    document_version.title = document_version.document.title
    document_version.save
  end
end
