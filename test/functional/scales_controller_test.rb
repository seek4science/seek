require 'test_helper'

class ScalesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as(Factory(:user))
    @scale1 = Factory(:scale)
    @scale2 = Factory(:scale)
    @scale3 = Factory(:scale)
    m=Factory(:model,:policy=>Factory(:public_policy))
    m.scales=[@scale1,@scale3]
    m.save!
    m2=Factory(:model,:policy=>Factory(:private_policy))
    m2.scales=@scale1
    m2.save!
    df=Factory(:data_file,:policy=>Factory(:public_policy))
    df.scales=[@scale2,@scale3]
    df.save!
    df2=Factory(:data_file,:policy=>Factory(:public_policy))
    df2.scales=[@scale3]
    df2.save!
  end

  test "index" do
    logout
    get :index
    assert_response :success
    assert_select "ul#scale_list" do
      assert_select "li##{@scale1.key}",:text=>@scale1.title + " -"
      assert_select "li##{@scale2.key}",:text=>@scale2.title + " -"
      assert_select "li##{@scale3.key}",:text=>@scale3.title + " -"
    end
  end

  test "show" do
    logout
    get :show,:id=>@scale1.id
    assert_response :success
    assert_select "ul#scale_list" do
      assert_select "li##{@scale1.key}",:text=>@scale1.title + " -"
      assert_select "li##{@scale2.key}",:text=>@scale2.title + " -"
      assert_select "li##{@scale3.key}",:text=>@scale3.title + " -"
    end
  end

  test "show all" do
    logout
    get :show,:id=>"all"
    assert_response :success
    assert_select "ul#scale_list" do
      assert_select "li##{@scale1.key}",:text=>@scale1.title + " -"
      assert_select "li##{@scale2.key}",:text=>@scale2.title + " -"
      assert_select "li##{@scale3.key}",:text=>@scale3.title + " -"
    end
  end
end
