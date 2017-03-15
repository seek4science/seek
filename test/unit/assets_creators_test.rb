require 'test_helper'

class AssetsCreatorsTest < ActiveSupport::TestCase
  def setup
    user = Factory :user
    User.current_user = user
    @resource = Factory :sop, contributor: User.current_user, projects: user.person.projects
  end

  def teardown
    User.current_user = nil
  end

  test 'adding_a_creator' do
    creator = Factory :person
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])
    assert_difference('@resource.creators.count') do
      assert_difference('AssetsCreator.count') do
        AssetsCreator.add_or_update_creator_list(@resource, params)
      end
    end
  end

  test 'updating_an_creator' do
    # Set creator
    creator = Factory :person
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    # Update creator
    new_creator = Factory :person

    params = ActiveSupport::JSON.encode([[new_creator.name, new_creator.id]])
    assert_no_difference('AssetsCreator.count') do
      assert_no_difference('@resource.creators.count') do
        AssetsCreator.add_or_update_creator_list(@resource, params)
      end
    end

    assert_not_equal @resource.creators.first, creator
    assert_equal @resource.creators.first, new_creator
  end

  test 'removing_an_creator' do
    # Set creator
    creator = Factory :person
    params =  ActiveSupport::JSON.encode([[creator.name, creator.id]])

    AssetsCreator.add_or_update_creator_list(@resource, params)

    # Remove creator
    params = ActiveSupport::JSON.encode([])
    assert_difference('@resource.creators.count', -1) do
      assert_difference('AssetsCreator.count', -1) do
        AssetsCreator.add_or_update_creator_list(@resource, params)
      end
    end
  end

  test 'changing_multiple_creators' do
    # Set creators
    creator_to_stay = Factory :person
    creator_to_remove = Factory :person
    params = ActiveSupport::JSON.encode([[creator_to_stay.name, creator_to_stay.id],
                                         [creator_to_remove.name, creator_to_remove.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    # Change creators
    new_creator = Factory :person
    params = ActiveSupport::JSON.encode([[creator_to_stay.name, creator_to_stay.id],
                                         [new_creator.name, new_creator.id]])
    AssetsCreator.add_or_update_creator_list(@resource, params)
    creators = @resource.creators
    assert_equal creators.count, 2
    assert creators.include?(creator_to_stay)
    assert creators.include?(new_creator)
    assert !creators.include?(creator_to_remove)
  end
end
