require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    person = FactoryBot.create(:person)
    p = person.projects.first
    s = FactoryBot.create(:document, projects: [p], contributor:person)
    assert_equal p, s.projects.first
  end

  test 'to_rdf' do
    person = FactoryBot.create(:person)
    person.add_to_project_and_institution(FactoryBot.create(:project),person.institutions.first)
    object = FactoryBot.create :document, description: 'An excellent Document', projects: person.projects, assay_ids: [FactoryBot.create(:assay).id], contributor:person
    FactoryBot.create :assets_creator, asset: object, creator: FactoryBot.create(:person)

    object = Document.find(object.id)
    refute_empty object.creators

    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/documents/#{object.id}"), reader.statements.first.subject

      #check for OPSK-1281 - where the creators weren't appearing
      assert_includes reader.statements.collect(&:predicate),"http://jermontology.org/ontology/JERMOntology#hasCreator"
      assert_includes reader.statements.collect(&:predicate),"http://rdfs.org/sioc/ns#has_creator"
    end
  end

  test 'title trimmed' do
    document = FactoryBot.create(:document, title: ' test document')
    assert_equal('test document', document.title)
  end

  test 'validation' do
    asset = Document.new title: 'fred', projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert asset.valid?

    asset = Document.new projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert !asset.valid?
  end

  test 'assay association' do
    document = FactoryBot.create(:document, policy: FactoryBot.create(:publicly_viewable_policy))
    assay = assays(:modelling_assay_with_data_and_relationship)
    assay_asset = assay_assets(:metabolomics_assay_asset1)
    assert_not_equal assay_asset.asset, document
    assert_not_equal assay_asset.assay, assay
    assay_asset.asset = document
    assay_asset.assay = assay
    User.with_current_user(assay.contributor.user) { assay_asset.save! }
    assay_asset.reload
    assert assay_asset.valid?
    assert_equal assay_asset.asset, document
    assert_equal assay_asset.assay, assay
  end

  test 'avatar key' do
    assert_nil  FactoryBot.create(:document).avatar_key
    assert  FactoryBot.create(:document).use_mime_type_for_avatar?

    assert_nil  FactoryBot.create(:document_version).avatar_key
    assert  FactoryBot.create(:document_version).use_mime_type_for_avatar?
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      document = FactoryBot.build(:document)
      refute document.persisted?
      document.save!
      document.reload
      assert document.valid?
      assert document.policy.valid?
      assert_equal Policy::NO_ACCESS, document.policy.access_type
      assert document.policy.permissions.blank?
    end
  end

  test 'version created for new document' do
    person = FactoryBot.create(:person)

    User.with_current_user(person.user) do
      document = FactoryBot.create(:document, contributor:person)

      assert document.save

      document = Document.find(document.id)

      assert_equal 1, document.version
      assert_equal 1, document.versions.size
      assert_equal document, document.versions.last.document
      assert_equal document.title, document.versions.first.title
    end

  end

  test 'create new version' do
    document = FactoryBot.create(:document)
    User.current_user = document.contributor
    document.save!
    document = Document.find(document.id)
    assert_equal 1, document.version
    assert_equal 1, document.versions.size
    assert_equal 'This Document', document.title

    document.save!
    document = Document.find(document.id)

    assert_equal 1, document.version
    assert_equal 1, document.versions.size
    assert_equal 'This Document', document.title

    document.title = 'Updated Document'

    document.save_as_new_version('Updated document as part of a test')
    document = Document.find(document.id)
    assert_equal 2, document.version
    assert_equal 2, document.versions.size
    assert_equal 'Updated Document', document.title
    assert_equal 'Updated Document', document.versions.last.title
    assert_equal 'Updated document as part of a test', document.versions.last.revision_comments
    assert_equal 'This Document', document.versions.first.title

    assert_equal 'This Document', document.find_version(1).title
    assert_equal 'Updated Document', document.find_version(2).title
  end

  test 'get previous version' do
    disable_authorization_checks do
      document = FactoryBot.create(:document, title: 'First version')

      document.title = 'Second Version'
      document.save_as_new_version('Second version')
      document.title = 'Third Version'
      document.save_as_new_version('Third version')
      document.title = 'Fourth Version'
      document.save_as_new_version('Fourth version')

      document.find_version(3).destroy!
      assert_equal 3, document.versions.length

      v1 = document.find_version(1)
      v2 = document.find_version(2)
      v3 = document.find_version(3)
      v4 = document.find_version(4)

      assert_nil v3
      assert_equal v1, v2.previous_version
      assert_equal v2, v4.previous_version
      assert_nil v1.previous_version
    end
  end

  test 'project for document and document version match' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    document = FactoryBot.create(:document, projects: [project], contributor:person)
    assert_equal project, document.projects.first
    assert_equal project, document.latest_version.projects.first
  end

  test 'assign projects' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    User.with_current_user(person.user) do
      document = FactoryBot.create(:document, projects: [project],contributor:person)
      person.add_to_project_and_institution(FactoryBot.create(:project),person.institutions.first)
      projects = person.projects
      assert_equal 2,projects.count
      document.update(project_ids: projects.map(&:id))
      document.save!
      document.reload
      assert_equal projects.sort, document.projects.sort
    end
  end

  test 'versions destroyed as dependent' do
    document = FactoryBot.create(:document)
    assert_equal 1, document.versions.size, 'There should be 1 version of this Document'
    assert_difference(['Document.count', 'Document::Version.count'], -1) do
      User.current_user = document.contributor
      document.destroy
    end
  end

  test 'test uuid generated' do
    x = FactoryBot.build(:document)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = FactoryBot.build(:document)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing user' do
    document = FactoryBot.create :document, contributor: FactoryBot.create(:person)
    assert document.contributor
    assert_equal document.contributor.user, document.contributing_user
    assert_equal document.contributor.user, document.latest_version.contributing_user
  end

  test 'link to events' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      doc = FactoryBot.create(:document, contributor:person)
      assert_empty doc.events
      event = FactoryBot.create(:event, contributor:person)
      doc = FactoryBot.create(:document, events:[event], contributor:person)
      refute_empty doc.events
      assert_equal [event],doc.events
    end
  end

  test 'fails to link to none visible events' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      event = FactoryBot.create(:event)
      refute event.can_view?
      doc = FactoryBot.build(:document,events:[event], contributor:person)

      refute doc.save

      doc = FactoryBot.create(:document, contributor:person)

      doc.events << event

      refute doc.save
    end
  end
end
