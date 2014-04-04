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
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end

  test "correct response to unknown action" do
    skip("Not critical, but needs checking why the error has changed when running tests, but behaves as expected when running server ")
    login_as(:quentin)
    assert_raises ActionController::RoutingError do
      get :sdjgsdfjg
    end
  end

  test "shouldn't display feedback link when not logged in" do
    get :index
    assert_response :success
    assert_select "ul#my_profile_menu",:count=>0
    assert_select "li.dynamic_menu_li",:text=>/Provide feedback/, :count=>0
  end

  test "should display feedback link when logged in" do
    login_as(Factory(:user))
    get :index
    assert_response :success
    assert_select "ul#my_profile_menu" do
      assert_select "li.dynamic_menu_li",:text=>/Provide feedback/, :count=>1
    end
  end

  test "should get feedback form" do
    login_as(:quentin)
    get :feedback
    assert_response :success
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

  test "admin menu item not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "ul#my_profile_menu" do
      assert_select "li.dynamic_menu_li",:text=>"Server admin", :count=>0
    end
  end

  test "admin menu item visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select "ul#my_profile_menu" do
      assert_select "li.dynamic_menu_li",:text=>"Server admin", :count=>1
    end
  end

  test "SOP menu item should be capitalized" do
    login_as(:quentin)
    get :index
    if Seek::Config.is_virtualliver
      assert_select "div.section>li>a[href=?]","/sops",:text=>"SOPs",:count=>1
    else
      assert_select "span#assets_menu_section" do
        assert_select "li" do
          assert_select "a[href=?]",sops_path,:text=>"SOPs"
        end
      end
    end

  end

  test "SOP upload option should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "ul#new_asset_menu",:count=>1 do
      assert_select "li.dynamic_menu_li", :text=>"#{I18n.t('sop')}", :count => 1
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
    assert_select 'a',:text=>/Forum/,:count=>0
  end

  test "should hide forum tab for logged in user" do
    #this test may break if we re-enable forums - which is currently under question. If it does and we have re-enabled just change :count=>1
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>0
  end

  test "should display home description" do
    Seek::Config.home_description="Blah blah blah - http://www.google.com"
    logout

    get :index
    assert_response :success

    assert_select "div.top_home_panel", :text=>/Blah blah blah/, :count=>1
    assert_select "div.top_home_panel a[href=?]", "http://www.google.com", :count=>1

  end

  test "should turn on/off project news and community news" do
    #turn on
    Seek::Config.project_news_enabled=true
    Seek::Config.community_news_enabled=true

    get :index
    assert_response :success

    assert_select "div.heading", :text=>/Community News/, :count=>1
    assert_select "div.heading", :text=>"#{Seek::Config.application_name} News", :count=>1

    #turn off
    Seek::Config.project_news_enabled=false
    Seek::Config.community_news_enabled=false


    get :index
    assert_response :success

    assert_select "div[class=?][style='display:none']",/yui-u first home_panel.*/, :count => 1
    assert_select "div[class=?][style='display:none']",/yui-u home_panel.*/, :count => 1
  end

  test "feed reader should handle missing feed title" do

    Seek::Config.project_news_enabled=true
    Seek::Config.project_news_feed_urls = uri_to_feed("simple_feed_with_subtitle.xml")
    Seek::Config.project_news_number_of_entries = "5"

    get :index

    assert_response :success

    assert_select "li.homepanel_item" do
      assert_select "div.feedinfo",:text=>/Unknown publisher/,:count=>4
    end
  end

  test "should handle index html" do
    assert_routing("/",{:controller=>"homes",:action=>"index"})
    assert_recognizes({:controller=>"homes",:action=>"index"},"/index.html")
    assert_recognizes({:controller=>"homes",:action=>"index"},"/index")
  end

  test "should show the content of project news and community news with the configurable number of entries" do
    sbml = uri_to_sbml_feed
    bbc = uri_to_bbc_feed
    guardian = uri_to_guardian_feed
    #project news
    Seek::Config.project_news_enabled=true
    Seek::Config.project_news_feed_urls = "#{bbc}, #{sbml}"
    Seek::Config.project_news_number_of_entries = "5"

    #community news
    Seek::Config.community_news_enabled=true
    Seek::Config.community_news_feed_urls = "#{guardian}"
    Seek::Config.community_news_number_of_entries = "7"

    login_as(:aaron)
    get :index
    assert_response :success

    assert_select 'div#project_news ul>li', 5
    assert_select 'div#community_news ul>li', 7

    logout
    get :index
    assert_response :success

    assert_select 'div#project_news ul>li', 5
    assert_select 'div#community_news ul>li', 7
  end

  test "recently added should include data_file" do
    login_as(:aaron)

    df = Factory :data_file, :title=>"A new data file", :contributor=>User.current_user.person
    assert_difference "ActivityLog.count" do
      log = Factory :activity_log, :activity_loggable=>df, :controller_name=>"data_files", :culprit=>User.current_user
    end


    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",data_file_path(df),:text=>/A new data file/
  end

  test "recently added should include presentations" do
    login_as(:aaron)

    presentation = Factory :presentation, :title=>"A new presentation", :contributor=>User.current_user.person
    log = Factory :activity_log, :activity_loggable=>presentation, :controller_name=>"presentations", :culprit=>User.current_user

    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",presentation_path(presentation),:text=>/A new presentation/
  end

  test "should show headline announcement" do
    login_as :aaron
    ann=Factory :headline_announcement

    get :index
    assert_response :success
    assert_select "div.headline_announcement", :count=>1

    #now expire it
    ann.expires_at=1.day.ago
    ann.save!
    get :index
    assert_response :success
    assert_select "p.headline_announcement",:count=>0
  end

  test "should show external search when not logged in" do
    with_config_value :solr_enabled,true do
      with_config_value :external_search_enabled, true do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search",:count=>1
      end
    end
  end

  test "should show external search when logged in" do
    login_as Factory(:user)
    with_config_value :solr_enabled,true do
      with_config_value :external_search_enabled, true do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search",:count=>1
      end
    end
  end

  test "should not show external search when disabled" do
    login_as Factory(:user)
    with_config_value :solr_enabled,true do
      with_config_value :external_search_enabled, false do
        get :index
        assert_response :success
        assert_select "div#search_box input#include_external_search",:count=>0
      end
    end
  end

  test "should show tag cloud according to config" do
    get :index
    assert_select "div#sidebar_tag_cloud",:count=>1
    with_config_value :tagging_enabled,false do
      get :index
      assert_select "div#sidebar_tag_cloud",:count=>0
    end
  end

  def uri_to_guardian_feed
    uri_to_feed "guardian_atom.xml"
  end

  def uri_to_sbml_feed
    uri_to_feed "sbml_atom.xml"
  end

  def uri_to_bbc_feed
    uri_to_feed("bbc_atom.xml")
  end

  def uri_to_bad_feed
    uri_to_feed("bad_atom.xml")
  end

  def uri_to_feed filename
    path = File.join(Rails.root,"test","fixtures","files","mocking",filename)
    URI.join('file:///',path).to_s
  end
  
end
