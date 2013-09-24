require 'test_helper'

class ScalableTest < ActiveSupport::TestCase

  def setup
    User.current_user = Factory(:user)
    @model = Factory :model
    @small_scale = Factory :scale, :title=>"small",:pos=>1
    @medium_scale = Factory :scale, :title=>"medium",:pos=>2
    @large_scale = Factory :scale, :title=>"large",:pos=>3
  end

  test "models have scales" do
    assert @model.respond_to?(:scales)
    assert_equal [],@model.scales
  end

  test "assign scales" do
    @model.scales = [@small_scale]
    @model.save
    scales = Model.find(@model.id).scales
    assert_equal [@small_scale],scales
  end

  test "retrieved scales are ordered" do
    @model.scales = [@large_scale,@small_scale,@medium_scale]
    @model.save
    scales = Model.find(@model.id).scales
    assert_equal [@small_scale,@medium_scale,@large_scale],scales
  end

end