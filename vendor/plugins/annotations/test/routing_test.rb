require "#{File.dirname(__FILE__)}/test_helper"

class RoutingTest < ActiveSupport::TestCase

  def setup
    ActionController::Routing::Routes.draw do |map|
      Annotations.map_routes(map)
    end
  end

  def test_annotations_route
    assert_recognition :get, "/annotations", :controller => "annotations", :action => "index"
  end

  private

    # From: http://guides.rubyonrails.org/creating_plugins.html#_add_a_custom_route 
    #
    # yes, I know about assert_recognizes, but it has proven problematic to
    # use in these tests, since it uses RouteSet#recognize (which actually
    # tries to instantiate the controller) and because it uses an awkward
    # parameter order.
    def assert_recognition(method, path, options)
      result = ActionController::Routing::Routes.recognize_path(path, :method => method)
      assert_equal options, result
    end
end