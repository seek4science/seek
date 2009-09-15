require File.dirname(__FILE__) + '/../test_helper'

class SopTest < ActiveSupport::TestCase
  fixtures :all

  test "project" do
    s=sops(:editable_sop)
    p=projects(:sysmo_project)
    assert_equal p,s.asset.project
    assert_equal p,s.project
  end
end
