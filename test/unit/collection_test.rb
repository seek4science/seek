require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    person = FactoryBot.create(:person)
    p = person.projects.first
    s = FactoryBot.create(:collection, projects: [p], contributor:person)
    assert_equal p, s.projects.first
  end

  test 'to_rdf' do
    person = FactoryBot.create(:person)
    person.add_to_project_and_institution(FactoryBot.create(:project),person.institutions.first)
    object = FactoryBot.create(:populated_collection, description: 'An excellent Collection', projects: person.projects, contributor: person)
    FactoryBot.create :assets_creator, asset: object, creator: FactoryBot.create(:person)

    object = Collection.find(object.id)
    refute_empty object.creators

    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/collections/#{object.id}"), reader.statements.first.subject

      #check for OPSK-1281 - where the creators weren't appearing
      assert_includes reader.statements.collect(&:predicate),"http://jermontology.org/ontology/JERMOntology#hasCreator"
      assert_includes reader.statements.collect(&:predicate),"http://rdfs.org/sioc/ns#has_creator"
    end
  end

  test 'title trimmed' do
    collection = FactoryBot.create(:collection, title: ' test collection')
    assert_equal('test collection', collection.title)
  end

  test 'validation' do
    asset = Collection.new title: 'fred', projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert asset.valid?

    asset = Collection.new projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert !asset.valid?
  end

  test 'avatar' do
    assert FactoryBot.create(:collection).defines_own_avatar?
  end

  test 'policy defaults to visible' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      collection = FactoryBot.build(:collection)
      refute collection.persisted?
      collection.save!
      collection.reload
      assert collection.valid?
      assert collection.policy.valid?
      assert_equal Policy::ACCESSIBLE, collection.policy.access_type
      assert collection.policy.permissions.blank?
    end
  end

  test 'assign projects' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    User.with_current_user(person.user) do
      collection = FactoryBot.create(:collection, projects: [project], contributor: person)
      person.add_to_project_and_institution(FactoryBot.create(:project), person.institutions.first)
      projects = person.projects
      assert_equal 2,projects.count
      collection.update(project_ids: projects.map(&:id))
      collection.save!
      collection.reload
      assert_equal projects.sort, collection.projects.sort
    end
  end

  test 'test uuid generated' do
    x = FactoryBot.build(:collection)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = FactoryBot.build(:collection)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing user' do
    collection = FactoryBot.create :collection, contributor: FactoryBot.create(:person)
    assert collection.contributor
    assert_equal collection.contributor.user, collection.contributing_user
  end

  test 'collection assets' do
    collection = FactoryBot.create(:collection)
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    data_file = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
    document = FactoryBot.create(:document, policy: FactoryBot.create(:public_policy))
    assert_empty collection.items
    assert_empty collection.assets

    assert_difference('CollectionItem.count', 3) do
      collection.items.create!(asset: sop)
      collection.items.create!(asset: data_file)
      collection.items.create!(asset: document)
    end

    assert_includes collection.assets, sop
    assert_includes collection.assets, data_file
    assert_includes collection.assets, document
  end

  test 'collection assets are unique' do
    collection = FactoryBot.create(:collection)
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    assert collection.items.create(asset: sop)

    assert_no_difference('CollectionItem.count') do
      item = collection.items.create(asset: sop)
      assert item.errors.added?(:asset_id, :taken, value: sop.id)
    end
  end

  test 'collection cannot include itself' do
    collection = FactoryBot.create(:collection)

    assert_no_difference('CollectionItem.count') do
      item = collection.items.create(asset: collection)
      assert item.errors[:asset].join.include?('collection itself')
    end
  end

  test 'collection items destroyed with collection' do
    collection = FactoryBot.create(:populated_collection)

    assert_difference('Collection.count', -1) do
      assert_difference('CollectionItem.count', -1) do
        disable_authorization_checks { collection.destroy }
      end
    end
  end

  test 'collection item asset must exist' do
    collection = FactoryBot.create(:collection)

    item = collection.items.build(asset_id: Sop.maximum(:id) + 1, asset_type: 'Sop')
    refute item.valid?
    assert item.errors.added?(:asset, :blank)
  end

  test 'collection item asset must be viewable' do
    collection = FactoryBot.create(:collection)
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:private_policy))
    refute sop.can_view?
    item = collection.items.build(asset: sop)
    refute item.save
    assert item.errors[:base].join.include?('You do not have permission to view')
  end

  test 'deleting the asset also deletes collection items' do
    document = FactoryBot.create(:document)
    collection1 = FactoryBot.create(:collection)
    collection2 = FactoryBot.create(:collection)
    disable_authorization_checks do
      collection1.items.create!(asset: document)
      collection2.items.create!(asset: document)
    end
    assert_difference('CollectionItem.count', -2) do
      disable_authorization_checks { document.destroy }
    end
  end

  test 'can add all valid types to a collection' do
    collection = FactoryBot.create(:collection)
    assert_empty collection.items
    assert_empty collection.assets

    types = Seek::Util.persistent_classes.select { |c| c.name != 'Project' && c.name != 'Collection' && c.method_defined?(:collections) }
    types.each do |type|
      opts = [type.name.underscore.to_sym]
      opts << { policy: FactoryBot.create(:public_policy) } if type.method_defined?(:policy)
      asset = FactoryBot.create(*opts)
      assert_difference('CollectionItem.count', 1, "#{type.name} could not be added to collection") do
        collection.items.create!(asset: asset)
      end

      assert_includes collection.reload.assets, asset
    end
  end
end
