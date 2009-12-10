require File.dirname(__FILE__) + '/../test_helper'

class FavouritesControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  include FavouritesHelper
  
  fixtures :users, :favourites, :projects, :people, :institutions
  
  def setup
    login_as(:quentin)
  end
  
  def test_add_valid_favourite
    project = projects(:one)    
    id = model_to_drag_id(project)
    
    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_nil fav
    
    xml_http_request(:put, :add, {:id=>id})
    
    assert_response :created
    
    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_not_nil fav
    
  end  
  
  def test_add_duplicate
    project = projects(:two)    
    id = model_to_drag_id(project)
    
    #sanity check that it does actually already exist
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_not_nil fav, "The project with id 2 should already exist for quentin"
    
    xml_http_request(:put, :add, {:id=>id})
    
    assert_response :unprocessable_entity
    
  end
  
  def test_valid_delete
    project = projects(:two)  
    id="fav_"+favourites(:one).id.to_s
    xml_http_request(:delete, :delete, {:id=>id})
    assert_response :success
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_nil fav, "#{id} should have been destroyed"
  end
  
  def test_shouldnt_add_invalid_resource
    id="drag_DataFile_-1_25251251"
    fav=Favourite.find_by_resource_type_and_resource_id("DataFile",-1)
    assert_nil fav
    
    xml_http_request(:put, :add, {:id=>id})
    
    assert_response :unprocessable_entity
    
    fav=Favourite.find_by_resource_type_and_resource_id("DataFile",-1)
    assert_nil fav
  end
  
end
