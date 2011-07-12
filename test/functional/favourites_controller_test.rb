require 'test_helper'

class FavouritesControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  include FavouritesHelper
  
  fixtures :users, :favourites, :projects, :people, :institutions,:saved_searches
  
  def setup
    login_as(:quentin)
  end
  
  def test_add_valid_favourite
    project = projects(:one)    
    id = model_to_drag_id(project)
    
    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_nil fav
    
    xml_http_request(:post, :add, {:id=>id})
    
    assert_response :created
    
    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_not_nil fav
    
  end

  def test_add_with_get_fails
    project = projects(:one)
    id = model_to_drag_id(project)

    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_nil fav

    xml_http_request(:get, :add, {:id=>id})

    assert_response :unprocessable_entity

    fav=Favourite.find_by_resource_type_and_resource_id("Project",project.id)
    assert_nil fav

  end
  
  def test_add_duplicate
    project = projects(:two)    
    id = model_to_drag_id(project)
    
    #sanity check that it does actually already exist
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_not_nil fav, "The project with id 2 should already exist for quentin"
    
    xml_http_request(:post, :add, {:id=>id})
    
    assert_response :unprocessable_entity
    
  end

  def test_add_search

    assert_difference("Favourite.count",1) do
      assert_difference("SavedSearch.count",1) do
        xml_http_request(:post,:add,{:id=>"drag_search",:search_query=>"fred bloggs",:search_type=>"All"})
      end
    end
    assert_response :success
    fav=Favourite.last
    assert_equal "SavedSearch",fav.resource_type
    ss=fav.resource
    assert_equal "fred bloggs",ss.search_query
    assert_equal "All",ss.search_type
    
  end

  def test_cant_add_dupicate_search
    login_as(:pal_user)
    assert_no_difference("Favourite.count") do
      assert_no_difference("SavedSearch.count") do
        xml_http_request(:post,:add,{:id=>"drag_search",:search_query=>"cheese",:search_type=>"All"})
      end
    end
    assert_response :unprocessable_entity
  end

  def test_can_add_dupicate_search_with_different_type
    login_as(:pal_user)
    assert_difference("Favourite.count",1) do
      assert_difference("SavedSearch.count",1) do
        xml_http_request(:post,:add,{:id=>"drag_search",:search_query=>"cheese",:search_type=>"Assays"})
      end
    end
    assert_response :success
  end

  def test_delete_saved_search
    login_as(:pal_user)
    assert_not_nil Favourite.find_by_resource_type("SavedSearch")
    assert_not_nil SavedSearch.find_by_search_query("cheese")
    
    fav=favourites(:saved_search)
    ss=saved_searches(:cheese)
    id=fav.id
    assert_difference("Favourite.count",-1) do
      assert_difference("SavedSearch.count",-1) do
        xml_http_request(:delete,:delete,{:id=>"fav_#{id}"})
      end
    end
    assert_response :success
    
    assert_nil Favourite.find_by_resource_type("SavedSearch")
    assert_nil SavedSearch.find_by_search_query("cheese")
  end

  def test_valid_delete
    project = projects(:two)  
    id="fav_#{favourites(:project_fav).id}"
    xml_http_request(:delete, :delete, {:id=>id})
    assert_response :success
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_nil fav, "#{id} should have been destroyed"
  end

  def test_delete_with_get_fails
    project = projects(:two)
    id="fav_#{favourites(:project_fav).id}"
    xml_http_request(:get, :delete, {:id=>id})
    assert_response :unprocessable_entity
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_not_nil fav, "#{id} should have been destroyed"
  end

  def test_delete_with_post_fails
    project = projects(:two)
    id="fav_#{favourites(:project_fav).id}"
    xml_http_request(:post, :delete, {:id=>id})
    assert_response :unprocessable_entity
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_not_nil fav, "#{id} should have been destroyed"
  end

  def test_delete_with_put_fails
    project = projects(:two)
    id="fav_#{favourites(:project_fav).id}"
    xml_http_request(:put, :delete, {:id=>id})
    assert_response :unprocessable_entity
    fav=Favourite.find_by_resource_type_and_resource_id_and_user_id("Project",project.id,users(:quentin).id)
    assert_not_nil fav, "#{id} should have been destroyed"
  end
  
  def test_shouldnt_add_invalid_resource
    id="drag_DataFile_-1_25251251"
    fav=Favourite.find_by_resource_type_and_resource_id("DataFile",-1)
    assert_nil fav
    
    xml_http_request(:post, :add, {:id=>id})
    
    assert_response :unprocessable_entity
    
    fav=Favourite.find_by_resource_type_and_resource_id("DataFile",-1)
    assert_nil fav
  end
  
end
