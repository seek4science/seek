FactoryBot.define do
  # Document
  factory(:document) do
    title { 'This Document' }
    association :contributor, factory: :person
  
    after_build do |document|
      document.projects = [document.contributor.projects.first] if document.projects.empty?
    end
  
    after_create do |document|
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
  
  factory(:public_document, parent: :document) do
    policy { Factory(:downloadable_public_policy) }
  end
  
  factory(:private_document, parent: :document) do
    policy { Factory(:private_policy) }
  end
  
  factory(:min_document, class: Document) do
    with_project_contributor
    title { 'A Minimal Document' }
    policy { Factory(:downloadable_public_policy) }
    after_create do |document|
      document.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf',
                                             asset: document, asset_version: document.version)
    end
  end
  
  factory(:max_document, class: Document) do
    with_project_contributor
    title { 'A Maximal Document' }
    description { 'The important report we did for ~important-milestone~' }
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    policy { Factory(:downloadable_public_policy) }
    assays { [Factory(:public_assay)] }
    workflows {[Factory.build(:workflow, policy: Factory(:public_policy))]}
    relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
    after_create do |document|
      document.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: document, asset_version: document.version)
      document.annotate_with(['Document-tag1', 'Document-tag2', 'Document-tag3', 'Document-tag4', 'Document-tag5'], 'tag', document.contributor)
      document.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:api_pdf_document, parent: :document) do
    association :content_blob, factory: :blank_pdf_content_blob
  end
  
  # Factory::Version
  factory(:document_version, class: Document::Version) do
    association :document
    projects { document.projects }
    after_create do |document_version|
      document_version.document.version += 1
      document_version.document.save
      document_version.version = document_version.document.version
      document_version.title = document_version.document.title
      document_version.save
    end
  end
end
