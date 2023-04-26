FactoryBot.define do
  # Collection
  factory(:collection) do
    title { 'An empty collection' }
    with_project_contributor
  end

  factory(:populated_collection, parent: :collection) do
    title { 'A collection' }

    after_build do |collection|
      collection.items.build(asset: Factory(:public_document))
    end
  end

  factory(:public_collection, parent: :collection) do
    policy { Factory(:downloadable_public_policy) }
  end

  factory(:private_collection, parent: :collection) do
    policy { Factory(:private_policy) }
  end

  factory(:min_collection, class: Collection) do
    with_project_contributor
    title { 'A Minimal Collection' }
    policy { Factory(:downloadable_public_policy) }
  end

  factory(:max_collection, class: Collection) do
    with_project_contributor
    title { 'A Maximal Collection' }
    description { 'A collection of very interesting things' }
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    policy { Factory(:downloadable_public_policy) }
    relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
    after_create do |c|
      c.items = [
          Factory(:collection_item, comment: 'Readme!', collection: c, asset: Factory(:public_document, title: 'Readme')),
          Factory(:collection_item, comment: 'Secret info', collection: c, asset: Factory(:private_document, title: 'Secrets')),
          Factory(:collection_item, comment: 'The protocol', collection: c, asset: Factory(:sop, policy: Factory(:public_policy), title: 'Protocol')),
          Factory(:collection_item, comment: 'Data 1', collection: c, asset: Factory(:data_file, policy: Factory(:public_policy), title: 'Data 1')),
          Factory(:collection_item, comment: 'Data 2', collection: c, asset: Factory(:data_file, policy: Factory(:public_policy), title: 'Data 2')),
          Factory(:collection_item, comment: 'Bad data', collection: c, asset: Factory(:data_file, policy: Factory(:private_policy), title: 'Readme'))
      ]
      c.annotate_with(['Collection-tag1', 'Collection-tag2', 'Collection-tag3', 'Collection-tag4', 'Collection-tag5'], 'tag', c.contributor)
      c.save!
    end
    other_creators { 'Joe Bloggs' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end

  factory(:collection_with_all_types, parent: :public_collection) do
    after_create do |c|
      c.items = [
        Factory(:collection_item, comment: 'its a data_file', collection: c, asset: Factory(:data_file, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a sop', collection: c, asset: Factory(:sop, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a model', collection: c, asset: Factory(:model, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a document', collection: c, asset: Factory(:document, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a publication', collection: c, asset: Factory(:publication)),
        Factory(:collection_item, comment: 'its a presentation', collection: c, asset: Factory(:presentation, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a sample', collection: c, asset: Factory(:sample, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a event', collection: c, asset: Factory(:event, policy: Factory(:public_policy))),
        Factory(:collection_item, comment: 'its a workflow', collection: c, asset: Factory(:workflow, policy: Factory(:public_policy)))
      ]
    end
  end

  # CollectionItem
  factory(:collection_item) do
    ignore do
      contributor { Factory(:person) }
    end
    collection { Factory(:public_collection, contributor: contributor) }
    association :asset, factory: :public_document
  end

  factory(:min_collection_item, class: CollectionItem) do
    association :collection, factory: :public_collection
    association :asset, factory: :public_document
  end

  factory(:max_collection_item, class: CollectionItem) do
    association :collection, factory: :public_collection
    association :asset, factory: :public_document
    comment { 'A document' }
    order { 1 }
  end
end
