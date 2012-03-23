require 'test_helper'

class AssetsHelperTest < ActionView::TestCase
  fixtures :all

  def test_asset_version_links
    User.with_current_user Factory(:admin).user do
      model = models(:teusink)
      model_versions = model.versions
      assert_equal 2, model_versions.count
      model_version_links = asset_version_links model_versions
      assert_equal 2, model_version_links.count
      link1 = link_to('Teusink', "/models/#{model.id}" + "?version=1", {:target => '_blank'})
      link2 = link_to('Teusink', "/models/#{model.id}" + "?version=2", {:target => '_blank'})
      assert model_version_links.include?link1
      assert model_version_links.include?link2
    end
  end
end
