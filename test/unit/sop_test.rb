require 'test_helper'

class SopTest < ActiveSupport::TestCase

  fixtures :all

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @user = @person.user
  end

  test 'project' do
    s = sops(:editable_sop)
    p = projects(:sysmo_project)
    assert_equal p, s.projects.first
  end

  test 'to_rdf' do
    @person.add_to_project_and_institution(FactoryBot.create(:project),FactoryBot.create(:institution))
    object = FactoryBot.create :sop, description: 'An excellent SOP', contributor:@person, assay_ids: [FactoryBot.create(:assay).id]
    FactoryBot.create :assets_creator, asset: object, creator: FactoryBot.create(:person)

    object = Sop.find(object.id)
    refute_empty object.creators

    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/sops/#{object.id}"), reader.statements.first.subject

      #check for OPSK-1281 - where the creators weren't appearing
      assert_includes reader.statements.collect(&:predicate),"http://jermontology.org/ontology/JERMOntology#hasCreator"
      assert_includes reader.statements.collect(&:predicate),"http://rdfs.org/sioc/ns#has_creator"
    end
  end

  def test_title_trimmed
    sop = FactoryBot.create(:sop, title: ' test sop')
    assert_equal('test sop', sop.title)
  end

  test 'validation' do
    asset = Sop.new title: 'fred', projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert asset.valid?

    asset = Sop.new projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert !asset.valid?
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
      sop = FactoryBot.build(:sop)
      refute sop.persisted?
      sop.save!
      sop.reload
      assert sop.valid?
      assert sop.policy.valid?
      assert_equal Policy::NO_ACCESS, sop.policy.access_type
      assert sop.policy.permissions.blank?
    end
  end

  def test_version_created_for_new_sop
    sop = FactoryBot.create(:sop)

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
    assert_equal users(:owner_of_my_first_sop).person, sop_version.contributor
    assert_equal content_blobs(:content_blob_with_little_file2), sop_version.content_blob

    sop = sops(:my_first_sop)
    assert_equal sop.id, sop_version.sop_id

    assert_equal 1, sop.version
    assert_equal sop.title, sop.versions.first.title
  end

  def test_create_new_version
    sop = FactoryBot.create(:sop, title:'My First Favourite SOP')
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

    User.with_current_user(@person.user) do
      sop = FactoryBot.create(:sop, projects: [@project],contributor:@person)
      another_project = FactoryBot.create(:project)
      @person.add_to_project_and_institution(another_project,@person.institutions.first)
      projects = [@project, another_project]
      sop.update(project_ids: projects.map(&:id))
      sop.save!
      sop.reload
      assert_equal projects.sort, sop.projects.sort
    end

  end

  test 'sop with no contributor' do
    sop = sops(:sop_with_no_contributor)
    assert_nil sop.contributor
  end

  test 'versions destroyed as dependent' do
    sop = FactoryBot.create(:sop)
    assert_equal 1, sop.versions.size, 'There should be 1 version of this SOP'
    assert_difference(['Sop.count', 'Sop::Version.count'], -1) do
      User.current_user = sop.contributor.user
      sop.destroy
    end
  end

  test 'make sure content blob is preserved after deletion' do
    sop = FactoryBot.create(:sop)
    assert_not_nil sop.content_blob, 'Must have an associated content blob for this test to work'
    cb = sop.content_blob
    assert_difference('Sop.count', -1) do
      assert_no_difference('ContentBlob.count') do
        User.current_user = sop.contributor.user
        sop.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
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
    sop = FactoryBot.create :sop
    assert sop.contributor
    assert_equal sop.contributor.user, sop.contributing_user
    assert_equal sop.contributor.user, sop.latest_version.contributing_user
  end

  test 'new version sets appropriate contributor' do
    user = FactoryBot.create(:person).user
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    User.current_user = user

    assert_not_equal user, sop.contributor.user

    assert_difference('Sop::Version.count') do
      sop.save_as_new_version
    end

    version = sop.reload.versions.last
    assert_equal user, version.contributor.user
    assert_not_equal user, sop.contributor.user
  end

  test 'contributors method on versioned asset' do
    user = FactoryBot.create(:person).user
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    User.current_user = user

    assert_not_equal user, sop.contributor.user

    assert_difference('Sop::Version.count') do
      sop.save_as_new_version
    end

    assert_equal 2, sop.reload.contributors.length
    assert_includes sop.contributors, sop.contributor
    assert_includes sop.contributors, user.person
  end

  test 'sets default version visibility' do
    sop = FactoryBot.create(:sop)
    disable_authorization_checks do
      sop.save_as_new_version('Updated sop as part of a test')
    end

    v = sop.reload.latest_version

    assert_equal :public, v.visibility
    assert_equal v.class.default_visibility, v.visibility
  end

  test 'gets and sets version visibility' do
    sop = FactoryBot.create(:sop)
    disable_authorization_checks do
      sop.save_as_new_version('Updated sop as part of a test')
    end

    v = sop.reload.latest_version

    v.visibility = :private
    assert_equal :private, v.visibility
    v.visibility = :registered_users
    assert_equal :registered_users, v.visibility
    v.visibility = :public
    assert_equal :public, v.visibility
    v.visibility = :fish
    assert_not_equal :fish, v.visibility
    assert_equal v.class.default_visibility, v.visibility
  end

  test 'lists visible versions' do
    sop = FactoryBot.create(:sop)
    pub, reg, priv = nil

    disable_authorization_checks do
      pub = sop.latest_version
      pub.visibility = :public
      pub.save!

      sop.save_as_new_version('Registered users')
      reg = sop.reload.latest_version
      reg.visibility = :registered_users
      reg.save!

      sop.save_as_new_version('Private')
      priv = sop.reload.latest_version
      priv.visibility = :private
      priv.save!
    end

    assert_equal 3, sop.versions.length

    assert pub.visible?(nil)
    refute reg.visible?(nil)
    refute priv.visible?(nil)
    assert_equal [pub].sort, sop.visible_versions(nil).sort

    registered_user = FactoryBot.create(:person).user
    assert pub.visible?(registered_user)
    assert reg.visible?(registered_user)
    refute priv.visible?(registered_user)
    assert_equal [pub, reg].sort, sop.visible_versions(registered_user).sort

    manager = sop.contributor.user
    assert sop.can_manage?(manager)
    assert pub.visible?(manager)
    assert reg.visible?(manager)
    assert priv.visible?(manager)
    assert_equal [pub, reg, priv].sort, sop.visible_versions(manager).sort
  end

  test 'can change visibility?' do
    sop = FactoryBot.create(:sop)
    disable_authorization_checks do
      sop.save_as_new_version('This version has a DOI')
      sop.latest_version.update_column(:doi, '10.5072/test_doi')
      sop.save_as_new_version('Another version')
    end

    assert_equal 3, sop.versions.count

    v1 = sop.find_version(1)
    v2 = sop.find_version(2)
    v3 = sop.find_version(3)

    assert_nil v1.doi
    refute v1.latest_version?
    assert v1.can_change_visibility?

    refute_nil v2.doi
    refute v2.latest_version?
    refute v2.can_change_visibility?

    assert_nil v3.doi
    assert v3.latest_version?
    refute v3.can_change_visibility?
  end

end
