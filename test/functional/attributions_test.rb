require File.dirname(__FILE__) + '/../test_helper'

class AttributionsTest < ActionController::TestCase
  # use SopsController, because attributions don't have their own controller
  tests SopsController
  
  fixtures :users, :people
  
  
  include AuthenticatedTestHelper
  def setup
    login_as(:owner_of_my_first_sop)
  end
  
  
  def test_should_create_attribution_when_creating_new_sop
    # create a SOP and verify that both SOP and attribution get created
    assert_difference ['Sop.count', 'Relationship.count'] do
      post :create, :sop => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions"}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Sop", 1]])
    end
    assert_redirected_to sop_path(assigns(:sop))
  end
  
  
  def test_should_remove_attribution_on_update
    # create a SOP / attribution first
    assert_difference ['Sop.count', 'Relationship.count'] do
      post :create, :sop => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions"}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Sop", 1]])
    end
    assert_redirected_to sop_path(assigns(:sop))
    
    # update the SOP, but supply no data about attributions - these should be removed
    assert_no_difference('Sop.count') do
      assert_difference('Relationship.count', -1) do
        put :update, :id => assigns(:sop).id, :sop => {:title => "edited_title"}, :sharing => valid_sharing # NB! no attributions supplied - should remove if any existed for the sop
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
  end
  
  
  def test_attributions_are_getting_properly_synchronized
    # create a SOP / attributions first
    assert_difference('Sop.count') do
      assert_difference('Relationship.count', +2) do
        post :create, :sop => {:data => fixture_file_upload('files/little_file.txt'), :title => "test_attributions"}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Sop", 1], ["Sop", 2]])
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
  
    # store IDs of created attribution for further checks
    sop_id = assigns(:sop).id
    sop_instance = Sop.find(sop_id)
    
    assert_equal 2, sop_instance.attributions.length
    if sop_instance.attributions[0].object_id == 1
      attr_to_sop_one = sop_instance.attributions[0]
      attr_to_sop_two = sop_instance.attributions[1]
    else
      attr_to_sop_one = sop_instance.attributions[1]
      attr_to_sop_two = sop_instance.attributions[0]
    end
    
    # update the SOP: attributions data will add a new attribution, remove one old and keep one old unchanged - 
    # this leaves the total number of attributions unchaged
    assert_no_difference ['Sop.count', 'Relationship.count'] do
      put :update, :id => assigns(:sop).id, :sop => {:title => "edited_title"}, :sharing => valid_sharing, :attributions => ActiveSupport::JSON.encode([["Sop", 44], ["Sop", 2]])
    end
    assert_redirected_to sop_path(assigns(:sop))
    
    # verify it's still the same SOP
    assert_equal sop_id, assigns(:sop).id
    
    # --- Verify that synchronisation was performed correctly ---
    
    # attribution that was supposed to be deleted was really destroyed
    deleted_attr_to_sop_one = Relationship.find(:first, :conditions => { :subject_id => attr_to_sop_one.subject_id, :subject_type => attr_to_sop_one.subject_type,
                                                                         :predicate => attr_to_sop_one.predicate, :object_id => attr_to_sop_one.object_id,
                                                                         :object_type => attr_to_sop_one.object_type } )
    assert_equal nil, deleted_attr_to_sop_one
    
    
    
  end
  
  
  private
 
  def valid_sharing
    {
      :sharing_scope => Policy::ALL_REGISTERED_USERS,
      :access_type => Policy::VIEWING,
      :use_whitelist => false,
      :use_blacklist => false,
      :use_custom_sharing => false,
      :permissions => { :contributor_types => ActiveSupport::JSON.encode([]), :values => ActiveSupport::JSON.encode({}) }
    }
  end
end