require 'test_helper'

class AssetAuthorTest < ActiveSupport::TestCase
  
  fixtures :all
  
  test "adding_an_author" do
    resource = sops(:my_first_sop)
    author = people(:fred)
    params =  ActiveSupport::JSON.encode([[author.name, author.id]])
    assert_difference('resource.asset.authors.count') do
      AssetAuthor.add_or_update_author_list(resource, params)
    end
  end
  
  test "updating_an_author" do
    resource = sops(:my_first_sop)
    #Set author
    author = people(:fred)
    params =  ActiveSupport::JSON.encode([[author.name, author.id]])
    AssetAuthor.add_or_update_author_list(resource, params)
    #Update author
    new_author = people(:one)
    params =  ActiveSupport::JSON.encode([[new_author.name, new_author.id]])
    AssetAuthor.add_or_update_author_list(resource, params)
    assert_not_equal resource.asset.authors.first, author
    assert_equal resource.asset.authors.first, new_author
  end
  
  test "removing_an_author" do
    resource = sops(:my_first_sop)
    #Set author
    author = people(:fred)
    params =  ActiveSupport::JSON.encode([[author.name, author.id]])
    AssetAuthor.add_or_update_author_list(resource, params)
    #Remove author
    assert_difference('resource.asset.authors.count', -1) do
      params =  ActiveSupport::JSON.encode([])
      AssetAuthor.add_or_update_author_list(resource, params)
    end
  end
  
  test "changing_multiple_authors" do
    resource = sops(:my_first_sop)
    #Set authors
    author_to_stay = people(:one)
    author_to_remove = people(:two)
    params =  ActiveSupport::JSON.encode([[author_to_stay.name, author_to_stay.id],
                                          [author_to_remove.name, author_to_remove.id]])
    AssetAuthor.add_or_update_author_list(resource, params)
    #Change authors
    new_author = people(:three)
    params =  ActiveSupport::JSON.encode([[author_to_stay.name, author_to_stay.id],
                                          [new_author.name, new_author.id]])
    AssetAuthor.add_or_update_author_list(resource, params)
    authors = resource.asset.authors
    assert_equal authors.count, 2
    assert authors.include?(author_to_stay)
    assert authors.include?(new_author)
    assert !authors.include?(author_to_remove)    
  end
  
end
