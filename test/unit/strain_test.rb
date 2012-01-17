require 'test_helper'

class StrainTest < ActiveSupport::TestCase

  test "without default" do
    Strain.destroy_all
    Strain.create :title=>"fred",:is_dummy=>false
    Strain.create :title=>"default",:is_dummy=>true
    s=Strain.without_default
    assert 1,s.count
    assert_equal "fred",s.first.title
  end

end
