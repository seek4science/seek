require 'test_helper'

class AssetsCreatorsTest < ActiveSupport::TestCase
  def setup
    user = Factory :user
    User.current_user = user
    @resource = Factory :sop, contributor: User.current_user.person, projects: user.person.projects
  end

  def teardown
    User.current_user = nil
  end

  test 'adding a creator' do
    creator = Factory :person
    params = { creator_ids: [creator.id] }

    assert_difference('@resource.creators.count') do
      assert_difference('AssetsCreator.count') do
        @resource.update_attributes(params)
      end
    end
  end

  test 'updating a creator' do
    # Set creator
    creator = Factory :person
    params = { creator_ids: [creator.id] }
    @resource.update_attributes(params)

    # Update creator
    new_creator = Factory :person
    params = { creator_ids: [new_creator.id] }

    assert_no_difference('AssetsCreator.count') do
      assert_no_difference('@resource.creators.count') do
        @resource.update_attributes(params)
      end
    end

    assert_not_equal @resource.creators.first, creator
    assert_equal @resource.creators.first, new_creator
  end

  test 'removing a creator' do
    # Set creator
    creator = Factory :person
    params = { creator_ids: [creator.id] }
    @resource.update_attributes(params)

    # Remove creator
    params = { creator_ids: [] }

    assert_difference('@resource.creators.count', -1) do
      assert_difference('AssetsCreator.count', -1) do
        @resource.update_attributes(params)
      end
    end
  end

  test 'changing multiple creators' do
    # Set creators
    creator_to_stay = Factory :person
    creator_to_remove = Factory :person
    params = { creator_ids: [creator_to_stay.id, creator_to_remove.id] }
    @resource.update_attributes(params)

    # Change creators
    new_creator = Factory :person
    params = { creator_ids: [creator_to_stay.id, new_creator.id] }
    @resource.update_attributes(params)

    creators = @resource.creators
    assert_equal creators.count, 2
    assert creators.include?(creator_to_stay)
    assert creators.include?(new_creator)
    assert !creators.include?(creator_to_remove)
  end
end
