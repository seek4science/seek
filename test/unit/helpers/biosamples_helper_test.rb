require 'test_helper'

class BiosamplesHelperTest < ActionView::TestCase

  def test_asset_version_links
    admin = Factory(:admin)
    User.with_current_user admin.user do
      model = Factory(:teusink_model, :contributor=>admin.user,:title=>"Teusink")
      v = Factory(:model_version, :model=>model)
      model.reload
      model_versions = model.versions
      assert_equal 2, model_versions.count
      model_version_links = asset_version_links model_versions
      assert_equal 2, model_version_links.count
      link1 = link_to('Teusink', "/models/#{model.id}" + "?version=1")
      link2 = link_to('Teusink', "/models/#{model.id}" + "?version=2")
      assert model_version_links.include?link1
      assert model_version_links.include?link2
    end
  end
end
