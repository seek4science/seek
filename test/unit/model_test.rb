require File.dirname(__FILE__) + '/../test_helper'

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

  test "project" do
    model=models(:teusink)
    p=projects(:sysmo_project)
    assert_equal p,model.project
    assert_equal p,model.latest_version.project
  end

  test "creators through asset" do
    model=models(:teusink)
    assert_not_nil model.creators
    assert_equal 2,model.creators.size
    assert model.creators.include?(people(:pal))
    assert model.creators.include?(people(:person_for_model_owner))
    
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
