require File.dirname(__FILE__) + '/../test_helper'

class SopTest < ActiveSupport::TestCase
  fixtures :all
  
  test "project" do
    s=sops(:editable_sop)
    p=projects(:sysmo_project)
    assert_equal p,s.project
  end

  def test_title_trimmed 
    sop=Sop.new(:title=>" test sop")
    sop.save!
    assert_equal("test sop",sop.title)
  end
  
  def test_defaults_to_private_policy
    sop=Sop.new(:title=>"A sop with no policy")
    sop.save!
    sop.reload
    assert_not_nil sop.policy
    assert_equal Policy::PRIVATE, sop.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, sop.policy.access_type
    assert_equal false,sop.policy.use_whitelist
    assert_equal false,sop.policy.use_blacklist
    assert_equal false,sop.policy.use_custom_sharing
    assert sop.policy.permissions.empty?
  end

  def test_version_created_for_new_sop

    sop=Sop.new(:title=>"test sop")

    assert sop.save

    sop=Sop.find(sop.id)

    assert 1,sop.version
    assert 1,sop.versions.size
    assert_equal sop,sop.versions.last.sop
    assert_equal sop.title,sop.versions.first.title

  end

  #really just to test the fixtures for versions, but may as well leave here.
  def test_version_from_fixtures
    sop_version=sop_versions(:my_first_sop_v1)
    assert_equal 1,sop_version.version
    assert_equal users(:owner_of_my_first_sop),sop_version.contributor
    assert_equal content_blobs(:content_blob_with_little_file),sop_version.content_blob

    sop=sops(:my_first_sop)
    assert_equal sop.id,sop_version.sop_id

    assert_equal 1,sop.version
    assert_equal sop.title,sop.versions.first.title

  end  

  def test_create_new_version
    sop=sops(:my_first_sop)
    sop.save!
    sop=Sop.find(sop.id)
    assert_equal 1,sop.version
    assert_equal 1,sop.versions.size
    assert_equal "My First Favourite SOP",sop.title

    sop.save!
    sop=Sop.find(sop.id)

    assert_equal 1,sop.version
    assert_equal 1,sop.versions.size
    assert_equal "My First Favourite SOP",sop.title

    sop.title="Updated Sop"

    sop.save_as_new_version("Updated sop as part of a test")
    sop=Sop.find(sop.id)
    assert_equal 2,sop.version
    assert_equal 2,sop.versions.size
    assert_equal "Updated Sop",sop.title
    assert_equal "Updated Sop",sop.versions.last.title
    assert_equal "Updated sop as part of a test",sop.versions.last.revision_comments
    assert_equal "My First Favourite SOP",sop.versions.first.title

    assert_equal "My First Favourite SOP",sop.find_version(1).title
    assert_equal "Updated Sop",sop.find_version(2).title

  end

  def test_project_for_sop_and_sop_version_match
    sop=sops(:my_first_sop)
    project=projects(:sysmo_project)
    assert_equal project,sop.project
    assert_equal project,sop.latest_version.project
  end

  test "sop with no contributor" do
    sop=sops(:sop_with_no_contributor)
    assert_nil sop.contributor
  end

  test "versions destroyed as dependent" do
    sop = sops(:my_first_sop)
    assert_equal 1,sop.versions.size,"There should be 1 version of this SOP"   
    assert_difference(["Sop.count","Sop::Version.count"],-1) do
      sop.destroy
    end    
  end

  test "make sure content blob is preserved after deletion" do
    sop = sops(:my_first_sop)
    assert_not_nil sop.content_blob,"Must have an associated content blob for this test to work"
    cb=sop.content_blob
    assert_difference("Sop.count",-1) do
      assert_no_difference("ContentBlob.count") do
        sop.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    sop = sops(:my_first_sop)
    assert_difference("Sop.count",-1) do
      sop.destroy
    end
    assert_nil Sop.find_by_id(sop.id)
    assert_difference("Sop.count",1) do
      Sop.restore_trash!(sop.id)
    end
    assert_not_nil Sop.find_by_id(sop.id)
  end

  test "test uuid generated" do
    x = sops(:my_first_sop)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end
  
  test "uuid doesn't change" do
    x = sops(:my_first_sop)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
