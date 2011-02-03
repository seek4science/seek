require 'test_helper'

class ModelTest < ActiveSupport::TestCase
  fixtures :all    

  test "assocations" do
    model=models(:teusink)
    jws_env=recommended_model_environments(:jws)

    assert_equal jws_env,model.recommended_environment

    assert_equal "Teusink",model.title

    blob=content_blobs(:teusink_blob)
    assert_equal blob,model.content_blob
  end

  test "is asset?" do
    assert Model.is_asset?
    assert models(:teusink).is_asset?
    
    assert model_versions(:teusink_v1).is_asset?
  end

  test "avatar_key" do
    assert_equal "model_avatar",models(:teusink).avatar_key
    assert_equal "model_avatar",model_versions(:teusink_v1).avatar_key
  end

  test "authorization supported?" do
    assert Model.authorization_supported?
    assert models(:teusink).authorization_supported?
    assert model_versions(:teusink_v1).authorization_supported?
  end
  
  test "project" do
    model=models(:teusink)
    p=projects(:sysmo_project)
    assert_equal p,model.project
    assert_equal p,model.latest_version.project
  end
  
  def test_defaults_to_private_policy
    model=Model.new(:title=>"A sop with no policy")
    model.save!
    model.reload
    assert_not_nil model.policy
    assert_equal Policy::PRIVATE, model.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, model.policy.access_type
    assert_equal false,model.policy.use_whitelist
    assert_equal false,model.policy.use_blacklist
    assert_equal false,model.policy.use_custom_sharing
    assert model.policy.permissions.empty?
  end

  test "creators through asset" do
    model=models(:teusink)
    assert_not_nil model.creators
    assert_equal 2,model.creators.size
    assert model.creators.include?(people(:pal))
    assert model.creators.include?(people(:person_for_model_owner))
    
  end
  
  test "titled trimmed" do
    model=models(:teusink)
    model.title=" space"
    model.save!
    assert_equal "space",model.title
  end

  test "model with no contributor" do
    model=models(:model_with_no_contributor)
    assert_nil model.contributor
  end

  test "versions destroyed as dependent" do
    model=models(:teusink)
    assert_equal 2,model.versions.size,"There should be 2 versions of this Model"
    assert_difference("Model.count",-1) do
      assert_difference("Model::Version.count",-2) do
        model.destroy
      end
    end
  end

  test "make sure content blob is preserved after deletion" do
    model = models(:teusink)
    assert_not_nil model.content_blob,"Must have an associated content blob for this test to work"
    cb=model.content_blob
    assert_difference("Model.count",-1) do
      assert_no_difference("ContentBlob.count") do
        model.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    model = models(:teusink)
    assert_difference("Model.count",-1) do
      model.destroy
    end
    assert_nil Model.find_by_id(model.id)
    assert_difference("Model.count",1) do
      Model.restore_trash!(model.id)
    end
    assert_not_nil Model.find_by_id(model.id)
  end
  
  test "test uuid generated" do
    x = models(:teusink)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end

  test "uuid doesn't change" do
    x = models(:teusink)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
