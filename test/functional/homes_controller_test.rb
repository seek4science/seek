require 'test_helper'

class HomesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include HomesHelper

  test "test should be accessible to seek even if not logged in" do
    get :index
    assert_response :success
  end

  test "test title" do
    login_as(:quentin)
    get :index
    assert_select "title", :text => /The Sysmo SEEK.*/, :count => 1
  end

  test "correct response to unknown action" do
    login_as(:quentin)
    assert_raises ActionController::RoutingError do
      get :sdjgsdfjg
    end
  end

  test "shouldn't display feedback link when not logged in" do
    get :index
    assert_response :success
    assert_select "span#account_menu_section", :count => 0

    assert_select "li" do
      assert_select "a[href=?]", feedback_home_path, :text => I18n.t("menu.feedback"), :count => 0
    end

  end


  test "should get feedback form" do
    with_config_value :recaptcha_enabled, false do
      login_as(:quentin)
      get :feedback
      assert_response :success
    end
  end

  test "should not get feedback form as anonymous user" do
    get :feedback
    assert_response :redirect
  end

  test "should send feedback for anonymous user" do
    logout
    assert_emails(0) do
      post :send_feedback, :anon => false, :details => 'test feedback', :subject => 'test feedback'
    end
  end

  test "admin link not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]", admin_path, :count => 0
  end


  test "SOP menu item should be capitalized" do
    login_as(:quentin)

    as_virtualliver do
      get :index
      assert_select "div.section>li>a[href=?]", "/sops", :text => "SOPs", :count => 1
    end
    as_not_virtualliver do
      get :index
      assert_select "span#assets_menu_section" do
        assert_select "li" do
          assert_select "a[href=?]", sops_path, :text => "SOPs"
        end
      end
    end

  end

  test "SOP upload option should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "ul#new_asset_menu", :count => 1 do
      assert_select "li.dynamic_menu_li", :text => "#{I18n.t('sop')}", :count => 1
    end
  end

  test "hidden items do not appear in recent items" do
    model = Factory :model, :policy => Factory(:private_policy), :title => "A title"

    login_as(:quentin)
    get :index

    #difficult to use assert_select, because of the way the tabbernav tabs are constructed with javascript onLoad
    assert !@response.body.include?(model.title)
  end

  test 'root should route to sign_up when no user, otherwise to home' do
    User.find(:all).each do |u|
      u.delete
    end
    get :index
    assert_redirected_to :controller => 'users', :action => 'new'

    Factory(:user)
    get :index
    assert_response :success
  end

  test 'should hide the forum tab for unlogin user' do
    logout
    get :index
    assert_response :success
    assert_select 'a', :text => /Forum/, :count => 0
  end

  test "should hide forum tab for logged in user" do
    #this test may break if we re-enable forums - which is currently under question. If it does and we have re-enabled just change :count=>1
    as_not_virtualliver do
      login_as(:quentin)
      get :index
      assert_response :success
      assert_select 'a', :text => /Forum/, :count => 0
    end
  end


  test "should handle index html" do
    assert_routing("/", {:controller => "homes", :action => "index"})
    assert_recognizes({:controller => "homes", :action => "index"}, "/index.html")
    assert_recognizes({:controller => "homes", :action => "index"}, "/index")
  end


  test "ids of scales list should be the same as scales defined in Seek::Config.scales" do
    as_virtualliver do
      get :index
      assert_response :success
      scales = ["all"]
      scales += Scale.all.map(&:key)
      assert_select 'div#options ul>li', scales.length do
        scales.each do |scale|
          assert_select "[id=?]", scale
        end
      end
    end
  end

  test "scales slider on home page" do
    as_virtualliver do
      Seek::Config.solr_enabled = true
      get :index

      assert_response :success
      #vln home
      assert_select "div#wrapper" do
        #slider
        assert_select "ul#scale_list"
        assert_select "div#slider"
        #scale images
        assert_select "div#zoom img", :count => 6
      end

      #default scale is organism
      assert_select "div#scaled_items" do
        assert_select "div#organism_results"
      end

      #default scale for search filtering is Organism
      assert_select "div#search_box" do
        assert_select "select#scale option" do
          assert_select "[value=?]", /all/ do
            assert_select "[selected=?]", /selected/
          end
        end
      end
    end
  end


  test "should show headline announcement" do
    login_as :aaron
    ann=Factory :headline_announcement

    get :index
    assert_response :success

    assert_select "div.headline_announcement", :count => 1

    #now expire it
    ann.expires_at=1.day.ago
    ann.save!
    get :index
    assert_response :success
    assert_select "div.headline_announcement", :count => 0
  end

  test "should show external search when not logged in" do
    with_config_value :solr_enabled, true do
      with_config_value :external_search_enabled, true do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search", :count => 1
      end
    end
  end

  test "should show external search when logged in" do
    login_as Factory(:user)
    with_config_value :solr_enabled, true do
      with_config_value :external_search_enabled, true do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search", :count => 1
      end
    end
  end

  test "should not show external search when disabled" do
    login_as Factory(:user)
    with_config_value :solr_enabled, true do
      with_config_value :external_search_enabled, false do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search", :count => 0
      end
    end
  end
end

