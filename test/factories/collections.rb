# Collection
Factory.define(:collection) do |f|
  f.title 'An empty collection'
  f.association :contributor, factory: :person

  f.after_build do |collection|
    collection.projects = [collection.contributor.projects.first] if collection.projects.empty?
  end
end

Factory.define(:populated_collection, parent: :collection) do |f|
  f.title 'A collection'

  f.after_build do |collection|
    collection.projects = [collection.contributor.projects.first] if collection.projects.empty?
    collection.items.build(asset: Factory(:public_document))
  end
end

Factory.define(:public_collection, parent: :collection) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:private_collection, parent: :collection) do |f|
  f.policy { Factory(:private_policy) }
end

Factory.define(:min_collection, class: Collection) do |f|
  f.with_project_contributor
  f.title 'A Minimal Collection'
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:max_collection, class: Collection) do |f|
  f.with_project_contributor
  f.title 'A Maximal Collection'
  f.description 'A collection of very interesting things'
  f.policy { Factory(:downloadable_public_policy) }
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |c|
    c.items = [
        Factory(:collection_item, comment: 'Readme!', collection: c, asset: Factory(:public_document, title: 'Readme')),
        Factory(:collection_item, comment: 'Secret info', collection: c, asset: Factory(:private_document, title: 'Secrets')),
        Factory(:collection_item, comment: 'The protocol', collection: c, asset: Factory(:sop, policy: Factory(:public_policy), title: 'Protocol')),
        Factory(:collection_item, comment: 'Data 1', collection: c, asset: Factory(:data_file, policy: Factory(:public_policy), title: 'Data 1')),
        Factory(:collection_item, comment: 'Data 2', collection: c, asset: Factory(:data_file, policy: Factory(:public_policy), title: 'Data 2')),
        Factory(:collection_item, comment: 'Bad data', collection: c, asset: Factory(:data_file, policy: Factory(:private_policy), title: 'Readme'))
    ]
  end
  f.other_creators 'Blogs, Joe'
end

# CollectionItem
Factory.define(:collection_item) do |f|
  f.ignore do
    contributor { Factory(:person) }
  end
  f.collection { Factory(:public_collection, contributor: contributor) }
  f.association :asset, factory: :public_document
end

Factory.define(:min_collection_item, class: CollectionItem) do |f|
  f.association :collection, factory: :public_collection
  f.association :asset, factory: :public_document
end

Factory.define(:max_collection_item, class: CollectionItem) do |f|
  f.association :collection, factory: :public_collection
  f.association :asset, factory: :public_document
  f.comment 'A document'
  f.order 1
end
