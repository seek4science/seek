require 'test_helper'

class SopTest < ActiveSupport::TestCase
  fixtures :all

  test 'project' do
    s = sops(:editable_sop)
    p = projects(:sysmo_project)
    assert_equal p, s.projects.first
  end

  test 'to_rdf' do
    object = Factory :sop, description: 'An excellent SOP', projects: [Factory(:project), Factory(:project)], assay_ids: [Factory(:assay).id]
    Factory :assets_creator, asset: object, creator: Factory(:person)

    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/sops/#{object.id}"), reader.statements.first.subject

      #check for OPSK-1281 - where the creators weren't appearing
      assert_includes reader.statements.collect(&:predicate),"http://www.mygrid.org.uk/ontology/JERMOntology#hasCreator"
      assert_includes reader.statements.collect(&:predicate),"http://rdfs.org/sioc/ns#has_creator"
    end
  end

  def test_title_trimmed
    sop = Factory(:sop, title: ' test sop')
    assert_equal('test sop', sop.title)
  end

  test 'validation' do
    asset = Sop.new title: 'fred', projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert asset.valid?

    asset = Sop.new projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert !asset.valid?

    # VL only:allow no projects
    as_virtualliver do
      asset = Sop.new title: 'fred', policy: Factory(:private_policy)
      assert asset.valid?
    end
  end

  test 'assay association' do
    sop = sops(:sop_with_fully_public_policy)
    assay = assays(:modelling_assay_with_data_and_relationship)
    assay_asset = assay_assets(:metabolomics_assay_asset1)
    assert_not_equal assay_asset.asset, sop
    assert_not_equal assay_asset.assay, assay
    assay_asset.asset = sop
    assay_asset.assay = assay
    User.with_current_user(assay.contributor.user) { assay_asset.save! }
    assay_asset.reload
    assert assay_asset.valid?
    assert_equal assay_asset.asset, sop
    assert_equal assay_asset.assay, assay
  end

  def test_avatar_key
    assert_nil sops(:editable_sop).avatar_key
    assert sops(:editable_sop).use_mime_type_for_avatar?

    assert_nil sop_versions(:my_first_sop_v1).avatar_key
    assert sop_versions(:my_first_sop_v1).use_mime_type_for_avatar?
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      sop = Sop.new Factory.attributes_for(:sop, policy: nil)
      sop.save!
      sop.reload
      assert sop.valid?
      assert sop.policy.valid?
      assert_equal Policy::NO_ACCESS, sop.policy.access_type
      assert sop.policy.permissions.blank?
    end
  end

  def test_version_created_for_new_sop
    sop = Factory(:sop)

    assert sop.save

    sop = Sop.find(sop.id)

    assert_equal 1, sop.version
    assert_equal 1, sop.versions.size
    assert_equal sop, sop.versions.last.sop
    assert_equal sop.title, sop.versions.first.title
  end

  # really just to test the fixtures for versions, but may as well leave here.
  def test_version_from_fixtures
    sop_version = sop_versions(:my_first_sop_v1)
    assert_equal 1, sop_version.version
    assert_equal users(:owner_of_my_first_sop), sop_version.contributor
    assert_equal content_blobs(:content_blob_with_little_file2), sop_version.content_blob

    sop = sops(:my_first_sop)
    assert_equal sop.id, sop_version.sop_id

    assert_equal 1, sop.version
    assert_equal sop.title, sop.versions.first.title
  end

  def test_create_new_version
    sop = sops(:my_first_sop)
    User.current_user = sop.contributor
    sop.save!
    sop = Sop.find(sop.id)
    assert_equal 1, sop.version
    assert_equal 1, sop.versions.size
    assert_equal 'My First Favourite SOP', sop.title

    sop.save!
    sop = Sop.find(sop.id)

    assert_equal 1, sop.version
    assert_equal 1, sop.versions.size
    assert_equal 'My First Favourite SOP', sop.title

    sop.title = 'Updated Sop'

    sop.save_as_new_version('Updated sop as part of a test')
    sop = Sop.find(sop.id)
    assert_equal 2, sop.version
    assert_equal 2, sop.versions.size
    assert_equal 'Updated Sop', sop.title
    assert_equal 'Updated Sop', sop.versions.last.title
    assert_equal 'Updated sop as part of a test', sop.versions.last.revision_comments
    assert_equal 'My First Favourite SOP', sop.versions.first.title

    assert_equal 'My First Favourite SOP', sop.find_version(1).title
    assert_equal 'Updated Sop', sop.find_version(2).title
  end

  def test_project_for_sop_and_sop_version_match
    sop = sops(:my_first_sop)
    project = projects(:sysmo_project)
    assert_equal project, sop.projects.first
    assert_equal project, sop.latest_version.projects.first
  end

  test 'assign projects' do
    project = Factory(:project)
    sop = Factory(:sop, projects: [project])
    projects = [project, Factory(:project)]
    sop.update_attributes(project_ids: projects.map(&:id))
    sop.save!
    sop.reload
    assert_equal projects.sort, sop.projects.sort
  end

  test 'sop with no contributor' do
    sop = sops(:sop_with_no_contributor)
    assert_nil sop.contributor
  end

  test 'versions destroyed as dependent' do
    sop = sops(:my_first_sop)
    assert_equal 1, sop.versions.size, 'There should be 1 version of this SOP'
    assert_difference(['Sop.count', 'Sop::Version.count'], -1) do
      User.current_user = sop.contributor
      sop.destroy
    end
  end

  test 'make sure content blob is preserved after deletion' do
    sop = sops(:my_first_sop)
    assert_not_nil sop.content_blob, 'Must have an associated content blob for this test to work'
    cb = sop.content_blob
    assert_difference('Sop.count', -1) do
      assert_no_difference('ContentBlob.count') do
        User.current_user = sop.contributor
        sop.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test 'is restorable after destroy' do
    sop = Factory :sop, policy: Factory(:all_sysmo_viewable_policy), title: 'is it restorable?'
    blob_path = sop.content_blob.filepath
    User.current_user = sop.contributor
    assert_difference('Sop.count', -1) do
      sop.destroy
    end
    assert_nil Sop.find_by_title 'is it restorable?'
    assert_difference('Sop.count', 1) do
      disable_authorization_checks { Sop.restore_trash!(sop.id) }
    end
    sop = Sop.find_by_title('is it restorable?')
    refute_nil sop
    refute_nil sop.content_blob
    assert_equal blob_path, sop.content_blob.filepath
    assert File.exist?(blob_path)
  end

  test 'failing to delete due to can_delete still creates trash' do
    sop = Factory :sop, policy: Factory(:private_policy)
    assert_no_difference('Sop.count') do
      sop.destroy
    end
    assert_not_nil Sop.restore_trash(sop.id)
  end

  test 'test uuid generated' do
    x = sops(:my_first_sop)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = sops(:my_first_sop)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'contributing_user' do
    sop = Factory :sop
    assert sop.contributor
    assert_equal sop.contributor.user, sop.contributing_user
    assert_equal sop.contributor.user, sop.latest_version.contributing_user
    sop_without_contributor = Factory :sop, contributor: nil
    assert_nil sop_without_contributor.contributing_user
  end
end
