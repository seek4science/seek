require 'test_helper'

class AssetsCreatorsTest < ActiveSupport::TestCase
  def setup
    user = Factory :user
    User.current_user = user
    @resource = Factory :sop, contributor: User.current_user.person, projects: user.person.projects
    @person = Factory(:person)
    @sop = Factory(:sop, assets_creators_attributes: {
      '1' => {
        creator_id: @person.id
      },
      '2' => {
        given_name: 'Joe',
        family_name: 'Bloggs',
        affiliation: 'School of Rock',
        orcid: 'https://orcid.org/0000-0002-5111-7263'
      },
      '3' => {
        given_name: 'Jess',
        family_name: 'Jenkins',
        affiliation: 'School of Rock'
      }
    })
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

  test 'cannot add duplicate assets creators by creator_id' do
    disable_authorization_checks do
      assert_no_difference('AssetsCreator.count') do
        @sop.update_attributes(assets_creators_attributes: {
          '1233' => {
            creator_id: @person.id
          }
        })

        assert @sop.errors.added?('assets_creators.creator_id', :taken, value: @person.id)
      end
    end
  end

  test 'cannot add duplicate assets creators by orcid' do
    disable_authorization_checks do
      assert_no_difference('AssetsCreator.count') do
        @sop.update_attributes(assets_creators_attributes: {
          '4634' => {
            given_name: 'Someone',
            family_name: 'Else',
            orcid: 'https://orcid.org/0000-0002-5111-7263'
          }
        })

        assert @sop.errors.added?('assets_creators.orcid', :taken, value: 'https://orcid.org/0000-0002-5111-7263')
      end
    end
  end

  test 'cannot add duplicate assets creators by name in same institution' do
    disable_authorization_checks do
      assert_no_difference('AssetsCreator.count') do
        @sop.update_attributes(assets_creators_attributes: {
          '4634' => {
            given_name: 'Jess',
            family_name: 'Jenkins',
            affiliation: 'School of Rock'
          }
        })

        assert @sop.errors.added?('assets_creators.family_name', :taken, value: 'Jenkins')
      end
    end
  end

  test 'can add assets creators with same names in different institutions' do
    disable_authorization_checks do
      assert_difference('AssetsCreator.count', 1) do
        @sop.update_attributes(assets_creators_attributes: {
          '4634' => {
            given_name: 'Jess',
            family_name: 'Jenkins',
            affiliation: 'School of Jazz'
          }
        })

        assert @sop.valid?
      end
    end
  end

  test 'can add duplicate assets creators on different assets' do
    other_sop = Factory(:sop)

    disable_authorization_checks do
      assert_difference('AssetsCreator.count', 1) do
        other_sop.update_attributes(assets_creators_attributes: {
          '4634' => {
            given_name: 'Jess',
            family_name: 'Jenkins',
            affiliation: 'School of Rock'
          }
        })

        assert other_sop.valid?
      end
    end
  end
end
