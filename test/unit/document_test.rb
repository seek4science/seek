require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    p = projects(:sysmo_project)
    s = Factory(:document, projects: [p])
    assert_equal p, s.projects.first
  end

  test 'to_rdf' do
    object = Factory :document, description: 'An excellent Document', projects: [Factory(:project), Factory(:project)], assay_ids: [Factory(:assay).id]
    Factory :assets_creator, asset: object, creator: Factory(:person)

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
    document = Factory(:document, title: ' test document')
    assert_equal('test document', document.title)
  end

  test 'validation' do
    asset = Document.new title: 'fred', projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert asset.valid?

    asset = Document.new projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert !asset.valid?

    # VL only:allow no projects
    as_virtualliver do
      asset = Document.new title: 'fred', policy: Factory(:private_policy)
      assert asset.valid?
    end
  end

  test 'assay association' do
    document = Factory(:document)
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
    assert_nil  Factory(:document).avatar_key
    assert  Factory(:document).use_mime_type_for_avatar?

    assert_nil  Factory(:document_version).avatar_key
    assert  Factory(:document_version).use_mime_type_for_avatar?
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      document = Document.new Factory.attributes_for(:document, policy: nil)
      document.save!
      document.reload
      assert document.valid?
      assert document.policy.valid?
      assert_equal Policy::NO_ACCESS, document.policy.access_type
      assert document.policy.permissions.blank?
    end
  end

  test 'version created for new document' do
    document = Factory(:document)

    assert document.save

    document = Document.find(document.id)

    assert_equal 1, document.version
    assert_equal 1, document.versions.size
    assert_equal document, document.versions.last.document
    assert_equal document.title, document.versions.first.title
  end

  test 'create new version' do
    document = Factory(:document)
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

  test 'project for document and document version match' do
    project = projects(:sysmo_project)
    document = Factory(:document, projects: [project])
    assert_equal project, document.projects.first
    assert_equal project, document.latest_version.projects.first
  end

  test 'assign projects' do
    project = Factory(:project)
    document = Factory(:document, projects: [project])
    projects = [project, Factory(:project)]
    document.update_attributes(project_ids: projects.map(&:id))
    document.save!
    document.reload
    assert_equal projects.sort, document.projects.sort
  end

  test 'versions destroyed as dependent' do
    document = Factory(:document)
    assert_equal 1, document.versions.size, 'There should be 1 version of this Document'
    assert_difference(['Document.count', 'Document::Version.count'], -1) do
      User.current_user = document.contributor
      document.destroy
    end
  end

  test 'test uuid generated' do
    x = Factory.build(:document)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = Factory.build(:document)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing user' do
    document = Factory :document
    assert document.contributor
    assert_equal document.contributor.user, document.contributing_user
    assert_equal document.contributor.user, document.latest_version.contributing_user
    document_without_contributor = Factory :document, contributor: nil
    assert_nil document_without_contributor.contributing_user
  end
end
