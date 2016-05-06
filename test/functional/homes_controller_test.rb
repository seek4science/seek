require 'test_helper'

class HomesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include HomesHelper

  test 'funding page' do
    #check accessible outside
    get :funding
    assert_response :success
    assert_select 'h1',/seek funding/i
  end

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

  test "admin menu item not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "#user-menu" do
      assert_select "li a",:text=>"Server admin", :count=>0
    end
  end

  test "admin menu item visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select "#user-menu" do
      assert_select "li a",:text=>"Server admin", :count=>1
    end
  end

  test "SOP menu item should be capitalized" do
    login_as(:quentin)

    as_virtualliver do
      get :index
      assert_select "#browse-menu li>a[href=?]", "/sops", :text => "SOPs", :count => 1
    end
    as_not_virtualliver do
      get :index
      assert_select "#browse-menu" do
        assert_select "li" do
          assert_select "a[href=?]",sops_path,:text=>"SOPs"
        end
      end
    end

  end

  test "SOP upload option should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "li#create-menu ul.dropdown-menu",:count=>1 do
      assert_select "li>a", :text=>"#{I18n.t('sop')}", :count => 1
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
    User.all.each do |u|
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

    assert_select "div#home_description .panel-body", :text=>/Blah blah blah/, :count=>1
    assert_select "div#home_description .panel-body", :text=>/http:\/\/www.google.com/, :count=>1

  end

  test "should turn on/off project news and community news" do
    #turn on
    Seek::Config.news_enabled=true

    get :index
    assert_response :success

    assert_select "div.panel-heading", :text=>/News/, :count=>1

    #turn off
    Seek::Config.news_enabled=false

    get :index
    assert_response :success

    assert_select "div#news-feed", :count => 0
  end

  test "feed reader should handle missing feed title" do

    Seek::Config.news_enabled=true
    Seek::Config.news_feed_urls = uri_to_feed("simple_feed_with_subtitle.xml")
    Seek::Config.news_number_of_entries = "5"

    get :index

    assert_response :success

    assert_select "#news-feed ul.feed li" do
      assert_select "span.subtle",:text=>/Unknown publisher/,:count=>4
    end
  end

  test "should handle index html" do
    assert_routing("/",{:controller=>"homes",:action=>"index"})
    assert_recognizes({:controller=>"homes",:action=>"index"},"/index.html")
    assert_recognizes({:controller=>"homes",:action=>"index"},"/index")
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

  test "should show the content of project news and community news with the configurable number of entries" do
    sbml = uri_to_sbml_feed
    bbc = uri_to_bbc_feed

    Seek::Config.news_enabled=true
    Seek::Config.news_feed_urls = "#{bbc}, #{sbml}"
    Seek::Config.news_number_of_entries = "5"

    login_as(:aaron)
    get :index
    assert_response :success

    assert_select 'div#news-feed ul>li', 5

    logout
    get :index
    assert_response :success

    assert_select 'div#news-feed ul>li', 5
  end

  test "recently added should include data_file" do
    person = Factory(:person_in_project)

    df = Factory :data_file, :title=>"A new data file", :contributor=>person, :policy=>Factory(:public_policy)
    assert_difference "ActivityLog.count" do
      log = Factory :activity_log, :activity_loggable=>df, :controller_name=>"data_files", :culprit=>person.user
    end

    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",data_file_path(df),:text=>/A new data file/
  end

  test "recently added should include presentations" do
    person = Factory(:person_in_project)

    presentation = Factory :presentation, :title=>"A new presentation", :contributor=>person, :policy=>Factory(:public_policy)
    log = Factory :activity_log, :activity_loggable=>presentation, :controller_name=>"presentations", :culprit=>person.user

    get :index
    assert_response :success
    assert_select "div#recently_added ul>li>a[href=?]",presentation_path(presentation),:text=>/A new presentation/
  end

  test "should show headline announcement" do
    SiteAnnouncement.destroy_all
    login_as :aaron
    ann=Factory :headline_announcement

    get :index
    assert_response :success
    assert_select "span.headline_announcement_title", :count=>1

    #now expire it
    ann.expires_at=1.day.ago
    ann.save!
    get :index
    assert_response :success
    assert_select "span.headline_announcement_title",:count=>0
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

  test "should show tag cloud according to config when logged in" do
    login_as(Factory(:person))
    get :index
    assert_select "div#sidebar_tag_cloud",:count=>1
    with_config_value :tagging_enabled,false do
      get :index
      assert_select "div#sidebar_tag_cloud",:count=>0
    end
  end

  test "should display feed announcements when logged in" do
    login_as(Factory(:person))
    headline=Factory :headline_announcement, :show_in_feed=>false, :title=>"a headline announcement"
    feed=Factory :feed_announcement, :show_in_feed=>true,:title=>"a feed announcement"
    get :index
    assert_select "div#announcement_gadget" do
      assert_select "div.panel-body" do
        assert_select "ul.feed_announcement_list" do
          assert_select "li.feed_announcement span.announcement_title" do
            assert_select "a[href=?]",site_announcement_path(feed),:text=>"a feed announcement",:count=>1
            assert_select "a",:text=>"a headline announcement",:count=>0
          end
        end
      end
    end
  end

  test "documentation only shown when enabled" do
    with_config_value :documentation_enabled,true do
      get :index
      assert_select "li.dropdown span",:text=>"Help",:count=>1
    end

    with_config_value :documentation_enabled,false do
      get :index
      assert_select "li.dropdown span",:text=>"Help",:count=>0
    end
  end

  test "my recent contributions section works correctly" do
    person = Factory(:person)
    login_as(person)

    df = Factory :data_file, :title=>"A new data file", :contributor=>person, :policy=>Factory(:public_policy)
    sop = Factory :sop, :title=>"A new sop", :contributor=>person, :policy=>Factory(:public_policy)
    assay= Factory :assay, :title=>"A new assay", :contributor=>person, :policy=>Factory(:public_policy)

    Factory :activity_log, :activity_loggable => df, :controller_name=>"data_files", :culprit=>person.user
    Factory :activity_log, :activity_loggable => sop, :controller_name=>"sops", :culprit=>person.user
    Factory :activity_log, :activity_loggable => assay, :controller_name=>"assays", :culprit=>person.user

    get :index
    assert_response :success

    assert_select "div#my-recent-contributions .panel-body ul li", 3
    assert_select "div#my-recent-contributions .panel-body ul>li a[href=?]",data_file_path(df),:text=>/A new data file/
    assert_select "div#my-recent-contributions .panel-body ul li a[href=?]",sop_path(sop),:text=>/A new sop/
    assert_select "div#my-recent-contributions .panel-body ul li a[href=?]",assay_path(assay),:text=>/A new assay/

    sop.update_attributes(:title => 'An old sop')
    Factory :activity_log, :activity_loggable => sop, :controller_name=>"assays", :culprit=>person.user, :action => 'update'

    get :index
    assert_response :success
    assert_select "div#my-recent-contributions .panel-body ul li", 3
    assert_select "div#my-recent-contributions .panel-body ul>li a[href=?]",sop_path(sop),:text=>/An old sop/
    assert_select "div#my-recent-contributions .panel-body ul li a[href=?]",data_file_path(df),:text=>/A new data file/
    assert_select "div#my-recent-contributions .panel-body ul li a[href=?]",assay_path(assay),:text=>/A new assay/
    assert_select "div#my-recent-contributions .panel-body ul li a[href=?]",sop_path(sop),:text=>/A new sop/, :count => 0
  end

  test "can enabled/disable front page buttons" do
    login_as Factory(:user)
    with_config_value :front_page_buttons_enabled, true do
        get :index
        assert_response :success
        assert_select "a.seek-homepage-button",:count => 3
    end
    with_config_value :front_page_buttons_enabled, false do
      get :index
      assert_response :success
      assert_select "a.seek-homepage-button",:count => 0
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
