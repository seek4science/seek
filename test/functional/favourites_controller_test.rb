require File.dirname(__FILE__) + '/../test_helper'

class FavouritesControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  
  fixtures :users, :favourites, :projects, :people, :institutions
  
  def setup
    login_as(:quentin)
  end
  
  def test_add_valid_favourite
    
    id="drag_Project_1"
    
    fav=Favourite.find_by_model_name_and_asset_id("Project",1)
    assert_nil fav
    
    xml_http_request(:put, :add, {:id=>id})
    
    assert_response :created
    
    fav=Favourite.find_by_model_name_and_asset_id("Project",1)
    assert_not_nil fav
    
  end
  
  
  
  def test_add_duplicate
    id="drag_Project_2"
    
    #sanity check that it does actually already exist
    fav=Favourite.find_by_model_name_and_asset_id_and_user_id("Project",2,1)
    assert_not_nil fav, "The project with id 2 should already exist for quentin"
    
    xml_http_request(:put, :add, {:id=>id})
    
    assert_response :unprocessable_entity
    
  end
  
  def test_valid_delete
    id="fav_"+favourites(:one).id.to_s
    xml_http_request(:delete, :delete, {:id=>id})
    assert_response :success
    fav=Favourite.find_by_model_name_and_asset_id_and_user_id("Project",2,1)
    assert_nil fav, "#{id} should have been destroyed"
  end
  
end
