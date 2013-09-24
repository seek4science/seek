require 'test_helper'

class ScaleTest < ActiveSupport::TestCase

  test "ordering" do
    scale1 = Factory(:scale,:pos=>1)
    scale3 = Factory(:scale,:pos=>3)
    scale2 = Factory(:scale,:pos=>2)
    scale4 = Factory(:scale,:pos=>4)
    scales = Scale.all
    assert_equal [scale1,scale2,scale3,scale4],scales
  end

  test "validate presence" do
    scale = Scale.new(:title=>"scale",:key=>"scalek",:image_name=>"fred.jpg")
    assert scale.valid?
    scale.title=nil
    assert !scale.valid?
    scale.title="scale"
    scale.key=nil
    assert !scale.valid?
    scale.key="scalek"
    scale.image_name=nil
    assert !scale.valid?
  end

  test "validate uniqueness" do
    scale = Scale.new(:title=>"scale",:key=>"scalek",:image_name=>"fred.jpg")
    assert scale.valid?
    scale.save!
    scale = Scale.new(:title=>"scale1",:key=>"scalek1",:image_name=>"fred1.jpg")
    assert scale.valid?
    scale.title="scale"
    assert !scale.valid?
    scale.title="scale1"
    scale.key="scalek"
    assert !scale.valid?
    scale.key="scale"
    scale.image_name="fred.jpg"
    assert !scale.valid?
  end

  test "default pos" do
    scale = Scale.new(:title=>"scale",:key=>"scalek",:image_name=>"fred")
    assert_equal 1,scale.pos
  end

  test "with scale" do
    User.with_current_user(Factory(:user)) do
      scale1 = Factory(:scale)
      scale2 = Factory(:scale)
      scale3 = Factory(:scale)
      m=Factory(:model)
      m.scales=[scale1,scale3]
      m.save!
      m2=Factory(:model)
      m2.scales=scale1
      m2.save!
      df=Factory(:data_file)
      df.scales=[scale2,scale3]
      df.save!
      df2=Factory(:data_file)
      df2.scales=[scale3]
      df2.save!

      assets = Scale.with_scale(scale1)
      assert_equal 2,assets.size

      assert assets.include?(m)
      assert assets.include?(m2)

      assets = Scale.with_scale(scale2)
      assert_equal 1,assets.size
      assert assets.include?(df)

      assets = Scale.with_scale(scale3)
      assert_equal 3,assets.size
      assert assets.include?(m)
      assert assets.include?(df)
      assert assets.include?(df2)

      #also by id
      assets = Scale.with_scale(scale3.id)
      assert_equal 3,assets.size
      assert assets.include?(m)
      assert assets.include?(df)
      assert assets.include?(df2)

    end

  end

end
