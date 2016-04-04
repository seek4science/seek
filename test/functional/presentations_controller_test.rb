require 'test_helper'

class PresentationsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include RestTestCases
  include FunctionalAuthorizationTests

  def setup
    login_as Factory(:user)
  end

  def rest_api_test_object
    @object = Factory :presentation,:contributor=>User.current_user
    @object.tag_with "tag1"
    @object
  end

  test "index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:presentations)
  end

  test "can create with valid url" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://somewhere.com/piccy.png"
    presentation_attrs =   Factory.attributes_for(:presentation,
                                                  :project_ids => [Factory(:project).id]
                                                  )

    assert_difference "Presentation.count" do
      post :create,:presentation => presentation_attrs,:content_blobs => [{:data_url => "http://somewhere.com/piccy.png",:data=>nil}], :sharing => valid_sharing
    end
  end

  test "can create with local file" do
    presentation_attrs = Factory.attributes_for(:presentation,
                                                :contributor=>User.current_user,
                                                :project_ids => [Factory(:project).id])

    assert_difference "Presentation.count" do
      assert_difference "ActivityLog.count" do
        post :create,:presentation => presentation_attrs,:content_blobs => [{:data => file_for_upload}], :sharing => valid_sharing
      end
    end
  end

  test "can edit" do
    presentation = Factory :presentation,:contributor=>User.current_user

    get :edit,:id => presentation
    assert_response :success
  end

  test "can update" do
    presentation = Factory :presentation,:contributor=>User.current_user
    post :update,:id=>presentation,:presentation=>{:title=>"updated"}
    assert_redirected_to presentation_path(presentation)
  end

  test "should show presentation" do
    presentation = Factory :ppt_presentation,:contributor=>User.current_user
    assert_difference "ActivityLog.count" do
      get :show,:id=>presentation
    end

    assert_response :success

    assert_select "div.box_about_actor" do
      assert_select "p > b",:text=>/Filename:/
      assert_select "p",:text=>/ppt_presentation\.ppt/
      assert_select "p > b",:text=>/Format:/
      assert_select "p",:text=>/PowerPoint presentation/
      assert_select "p > b",:text=>/Size:/
      assert_select "p",:text=>/80.5 KB/
    end
  end

  test "can upload new version with valid url" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://somewhere.com/piccy.png"
    presentation = Factory :presentation,:contributor=>User.current_user

    assert_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{},
            :content_blobs => [{:data_url=>"http://somewhere.com/piccy.png"}]

       presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end

  test "can upload new version with valid filepath" do
    #by default, valid data_url is provided by content_blob in Factory
    presentation = Factory :presentation,:contributor=>User.current_user
    presentation.content_blob.url = nil
    presentation.content_blob.data = file_for_upload
    presentation.reload

    new_file_path = file_for_upload
    assert_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{},:content_blobs => [{:data=>new_file_path}]

       presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end


  test "cannot upload file with invalid url" do
    stub_request(:head,"http://www.blah.de/images/logo.png").to_raise(SocketError)
    presentation_attrs = Factory.build(:presentation, :contributor=>User.current_user).attributes #.symbolize_keys(turn string key to symbol)

    assert_no_difference "Presentation.count" do
     post :create, :presentation=>presentation_attrs,:content_blobs => [{:data_url=>"http://www.blah.de/images/logo.png"}]

    end
    assert_not_nil flash[:error]
  end

  test "cannot upload new version with invalid url" do
    stub_request(:any,"http://www.blah.de/images/liver-illustration.png").to_raise(SocketError)
    presentation = Factory :presentation,:contributor=>User.current_user
    new_data_url = "http://www.blah.de/images/liver-illustration.png"
    assert_no_difference "presentation.version" do
       post :new_version,:id => presentation,:presentation=>{},:content_blobs => [{:data_url=>new_data_url}]

       presentation.reload
    end
    assert_not_nil flash[:error]
  end

  test "can destroy" do
    presentation = Factory :presentation,:contributor=>User.current_user
    content_blob_id = presentation.content_blob.id
     assert_difference("Presentation.count",-1) do
       delete :destroy,:id => presentation
     end
    assert_redirected_to presentations_path

    #data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test "can subscribe" do
     presentation = Factory :presentation,:project_ids=>[Factory(:project).id],:contributor=>User.current_user
     assert_difference "presentation.subscriptions.count" do
        presentation.subscribed = true
        presentation.save
     end
  end

  test "update tags with ajax" do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    presentation = Factory :presentation,:contributor=>p.user


    assert presentation.annotations.empty?,"this presentation should have no tags for the test"

    golf = Factory :tag,:annotatable=>presentation,:source=>p2.user,:value=>"golf"
    Factory :tag,:annotatable=>presentation,:source=>p2.user,:value=>"sparrow"

    presentation.reload

    assert_equal ["golf","sparrow"],presentation.annotations.collect{|a| a.value.text}.sort
    assert_equal [],presentation.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],presentation.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

    xml_http_request :post, :update_annotations_ajax,{:id=>presentation,:tag_list=>"soup,#{golf.value.text}"}

    presentation.reload

    assert_equal ["golf","soup","sparrow"],presentation.annotations.collect{|a| a.value.text}.uniq.sort
    assert_equal ["golf","soup"],presentation.annotations.select{|a| a.source==p.user}.collect{|a| a.value.text}.sort
    assert_equal ["golf","sparrow"],presentation.annotations.select{|a|a.source==p2.user}.collect{|a| a.value.text}.sort

  end

  test "should download Presentation from standard route" do
    pres = Factory :ppt_presentation, :policy=>Factory(:public_policy)
    login_as(pres.contributor.user)
    assert_difference("ActivityLog.count") do
      get :download, :id=>pres.id
    end
    assert_response :success
    al=ActivityLog.last
    assert_equal "download",al.action
    assert_equal pres,al.activity_loggable
    assert_equal "attachment; filename=\"ppt_presentation.ppt\"",@response.header['Content-Disposition']
    assert_equal "application/vnd.ms-powerpoint",@response.header['Content-Type']
    assert_equal "82432",@response.header['Content-Length']
  end

  test "should set the other creators " do
    user = Factory(:user)
    presentation = Factory(:presentation, :contributor => user)
    login_as(user)
    assert presentation.can_manage?,"The presentation must be manageable for this test to succeed"
    put :update, :id => presentation, :presentation => {:other_creators => 'marry queen'}
    presentation.reload
    assert_equal 'marry queen', presentation.other_creators
  end

  test 'should show the other creators on the presentation index' do
    Factory(:presentation, :policy => Factory(:public_policy), :other_creators => 'another creator')
    get :index
    assert_select 'p.list_item_attribute', :text => /: another creator/, :count => 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    presentation=Factory(:presentation, :policy => Factory(:public_policy), :other_creators => 'another creator')
    get :show, :id => presentation
    assert_select 'div', :text => /another creator/, :count => 1
  end

  test 'should be able to view ms/open office ppt content' do
    ms_ppt_presentation = Factory(:ppt_presentation, :policy => Factory(:all_sysmo_downloadable_policy))
    assert ms_ppt_presentation.content_blob.is_content_viewable?
    get :show, :id => ms_ppt_presentation.id
    assert_response :success
    assert_select 'a', :text => /View content/, :count => 1

    openoffice_ppt_presentation = Factory(:odp_presentation, :policy => Factory(:all_sysmo_downloadable_policy))
    assert openoffice_ppt_presentation.content_blob.is_content_viewable?
    get :show, :id => openoffice_ppt_presentation.id
    assert_response :success
    assert_select 'a', :text => /View content/, :count => 1
  end

  test 'should display the file icon according to version' do
    ms_ppt_presentation = Factory(:ppt_presentation, :policy => Factory(:all_sysmo_downloadable_policy))
    get :show, :id => ms_ppt_presentation.id
    assert_response :success
    assert_select "img[src=?]", /\/assets\/file_icons\/small\/ppt\.png/

    #new version
    pdf_presentation = Factory(:presentation_version, :presentation => ms_ppt_presentation)
    content_blob = Factory(:pdf_content_blob, :asset => ms_ppt_presentation, :asset_version => 2)
    ms_ppt_presentation.reload
    assert_equal 2, ms_ppt_presentation.versions.count
    assert_not_nil ms_ppt_presentation.find_version(2).content_blob

    get :show, :id => ms_ppt_presentation.id, :version => 2
    assert_response :success
    assert_select "img[src=?]", /\/assets\/file_icons\/small\/pdf\.png/
  end

  test "filter by people, including creators, using nested routes" do
    assert_routing "people/7/presentations",{controller:"presentations",action:"index",person_id:"7"}

    person1=Factory(:person)
    person2=Factory(:person)

    pres1=Factory(:presentation,:contributor=>person1,:policy=>Factory(:public_policy))
    pres2=Factory(:presentation,:contributor=>person2,:policy=>Factory(:public_policy))

    pres3=Factory(:presentation,:contributor=>Factory(:person),:creators=>[person1],:policy=>Factory(:public_policy))
    pres4=Factory(:presentation,:contributor=>Factory(:person),:creators=>[person2],:policy=>Factory(:public_policy))


    get :index,:person_id=>person1.id
    assert_response :success

    assert_select "div.list_item_title" do
      assert_select "a[href=?]",presentation_path(pres1),:text=>pres1.title
      assert_select "a[href=?]",presentation_path(pres3),:text=>pres3.title

      assert_select "a[href=?]",presentation_path(pres2),:text=>pres2.title,:count=>0
      assert_select "a[href=?]",presentation_path(pres4),:text=>pres4.title,:count=>0
    end

  end


  test "should display null license text" do
    presentation = Factory :presentation, :policy => Factory(:public_policy)

    get :show, :id => presentation

    assert_select '.panel .panel-body span.none_text', :text => 'No license specified'
  end

  test "should display license" do
    presentation = Factory :presentation, :license => 'CC-BY-4.0', :policy => Factory(:public_policy)

    get :show, :id => presentation

    assert_select '.panel .panel-body a', :text => 'Creative Commons Attribution 4.0'
  end

  test "should display license for current version" do
    presentation = Factory :presentation, :license => 'CC-BY-4.0', :policy => Factory(:public_policy)
    presentationv = Factory :presentation_version_with_blob, :presentation => presentation

    presentation.update_attributes :license => 'CC0-1.0'

    get :show, :id => presentation, :version => 1
    assert_response :success
    assert_select '.panel .panel-body a', :text => 'Creative Commons Attribution 4.0'

    get :show, :id => presentation, :version => presentationv.version
    assert_response :success
    assert_select '.panel .panel-body a', :text => 'CC0 1.0'
  end

  test "should update license" do
    user = Factory(:person).user
    login_as(user)
    presentation = Factory :presentation, :policy => Factory(:public_policy), :contributor => user

    assert_nil presentation.license

    put :update, :id => presentation, :presentation => { :license => 'CC-BY-SA-4.0' }

    assert_response :redirect

    get :show, :id => presentation
    assert_select '.panel .panel-body a', :text => 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:presentation).license
  end

  test "programme presentations through nested routing" do
    assert_routing 'programmes/2/presentations', { controller: 'presentations' ,action: 'index', programme_id: '2'}
    programme = Factory(:programme)
    presentation = Factory(:presentation, projects: programme.projects, policy: Factory(:public_policy))
    presentation2 = Factory(:presentation, policy: Factory(:public_policy))

    get :index, programme_id: programme.id

    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]", presentation_path(presentation), text: presentation.title
      assert_select "a[href=?]", presentation_path(presentation2), text: presentation2.title, count: 0
    end
  end

end
