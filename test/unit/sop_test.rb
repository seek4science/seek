require File.dirname(__FILE__) + '/../test_helper'

class SopTest < ActiveSupport::TestCase
  fixtures :all

  test "project" do
    s=sops(:editable_sop)
    p=projects(:sysmo_project)
    assert_equal p,s.asset.project
    assert_equal p,s.project
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
  
end
