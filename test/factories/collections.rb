FactoryBot.define do
  # Collection
  factory(:collection) do
    title { 'An empty collection' }
    with_project_contributor
  end

  factory(:populated_collection, parent: :collection) do
    title { 'A collection' }

    after(:build) do |collection|
      collection.items.build(asset: FactoryBot.create(:public_document))
    end
  end

  factory(:public_collection, parent: :collection) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end

  factory(:private_collection, parent: :collection) do
    policy { FactoryBot.create(:private_policy) }
  end

  factory(:min_collection, class: Collection) do
    with_project_contributor
    title { 'A Minimal Collection' }
    policy { FactoryBot.create(:downloadable_public_policy) }
  end

  factory(:max_collection, class: Collection) do
    with_project_contributor
    title { 'A Maximal Collection' }
    description { 'A collection of very interesting things' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    policy { FactoryBot.create(:downloadable_public_policy) }
    relationships {[FactoryBot.create(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication))]}
    after(:create) do |c|
      c.items = [
          FactoryBot.create(:collection_item, comment: 'Readme!', collection: c, asset: FactoryBot.create(:public_document, title: 'Readme')),
          FactoryBot.create(:collection_item, comment: 'Secret info', collection: c, asset: FactoryBot.create(:private_document, title: 'Secrets')),
          FactoryBot.create(:collection_item, comment: 'The protocol', collection: c, asset: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy), title: 'Protocol')),
          FactoryBot.create(:collection_item, comment: 'Data 1', collection: c, asset: FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy), title: 'Data 1')),
          FactoryBot.create(:collection_item, comment: 'Data 2', collection: c, asset: FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy), title: 'Data 2')),
          FactoryBot.create(:collection_item, comment: 'Bad data', collection: c, asset: FactoryBot.create(:data_file, policy: FactoryBot.create(:private_policy), title: 'Readme'))
      ]
      c.annotate_with(['Collection-tag1', 'Collection-tag2', 'Collection-tag3', 'Collection-tag4', 'Collection-tag5'], 'tag', c.contributor)
      c.save!
    end
    other_creators { 'Joe Bloggs' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end

  factory(:collection_with_all_types, parent: :public_collection) do
    after(:create) do |c|
      c.items = [
        FactoryBot.create(:collection_item, comment: 'its a data_file', collection: c, asset: FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a sop', collection: c, asset: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a model', collection: c, asset: FactoryBot.create(:model, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a document', collection: c, asset: FactoryBot.create(:document, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a publication', collection: c, asset: FactoryBot.create(:publication)),
        FactoryBot.create(:collection_item, comment: 'its a presentation', collection: c, asset: FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a sample', collection: c, asset: FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a event', collection: c, asset: FactoryBot.create(:event, policy: FactoryBot.create(:public_policy))),
        FactoryBot.create(:collection_item, comment: 'its a workflow', collection: c, asset: FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy)))
      ]
    end
  end

  # CollectionItem
  factory(:collection_item) do
    transient do
      contributor { FactoryBot.create(:person) }
    end
    collection { FactoryBot.create(:public_collection, contributor: contributor) }
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
