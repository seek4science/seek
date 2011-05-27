require 'test_helper'

class AssetsCreatorsTest < ActiveSupport::TestCase
  
  fixtures :all

  def setup
    User.current_user = Factory :user
    @resource = Factory :sop, :contributor => User.current_user
  end

  def teardown
    User.current_user = nil
  end

  test "adding_a_creator" do
    creator = Factory :person
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])
    assert_difference('@resource.creators.count') do
      AssetsCreator.add_or_update_creator_list(@resource, params)
    end
  end
  
  test "updating_an_creator" do
    #Set creator
    creator = people(:fred)
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    #Update creator
    new_creator = people(:quentin_person)
    params =  ActiveSupport::JSON.encode([[new_creator.name, new_creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    assert_not_equal @resource.creators.first, creator
    assert_equal @resource.creators.first, new_creator
  end
  
  test "removing_an_creator" do
    #Set creator
    creator = people(:fred)
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    #Remove creator
    assert_difference('@resource.creators.count', -1) do
      params =  ActiveSupport::JSON.encode([])
      AssetsCreator.add_or_update_creator_list(@resource, params)
    end
  end
  
  test "changing_multiple_creators" do
    #Set creators
    creator_to_stay = people(:quentin_person)
    creator_to_remove = people(:aaron_person)
    params =  ActiveSupport::JSON.encode([[creator_to_stay.name, creator_to_stay.id],
                                          [creator_to_remove.name, creator_to_remove.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    #Change creators
    new_creator = people(:three)
    params =  ActiveSupport::JSON.encode([[creator_to_stay.name, creator_to_stay.id],
                                          [new_creator.name, new_creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    creators = @resource.creators
    assert_equal creators.count, 2
    assert creators.include?(creator_to_stay)
    assert creators.include?(new_creator)
    assert !creators.include?(creator_to_remove)
  end
  
end
