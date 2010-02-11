require File.dirname(__FILE__) + '/../test_helper'

class ModelTest < ActiveSupport::TestCase
  fixtures :models,:recommended_model_environments,:content_blobs,:assets,:projects

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
    assert_equal p,model.asset.project
    assert_equal p,model.project
    assert_equal p,model.latest_version.asset.project
    assert_equal p,model.latest_version.project
  end

  test "model with no contributor" do
    model=models(:model_with_no_contributor)
    assert_nil model.contributor
    assert_nil model.asset.contributor
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

end
