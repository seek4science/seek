require File.expand_path(File.dirname(__FILE__) + '/../../../../../../usr/lib/ruby/gems/1.8/gems/actionpack-2.3.17/lib/action_controller/test_case.rb')
module ActionController
  class TestCase < ActionController::TestCase
    def valid_model
      {:title => "Test", :projects => [projects(:sysmo_project)]}
    end
  end
end
