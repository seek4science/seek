require 'test_helper'

class AssetsCreatorsTest < ActiveSupport::TestCase
  def setup
    user = FactoryBot.create :user
    User.current_user = user
    @resource = FactoryBot.create :sop, contributor: User.current_user.person, projects: user.person.projects
    @person = FactoryBot.create(:person)
    @sop = FactoryBot.create(:sop, assets_creators_attributes: {
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
    creator = FactoryBot.create :person
    params = { creator_ids: [creator.id] }

    assert_difference('@resource.creators.count') do
      assert_difference('AssetsCreator.count') do
        @resource.update(params)
      end
    end
  end

  test 'updating a creator' do
    # Set creator
    creator = FactoryBot.create :person
    params = { creator_ids: [creator.id] }
    @resource.update(params)

    # Update creator
    new_creator = FactoryBot.create :person
    params = { creator_ids: [new_creator.id] }

    assert_no_difference('AssetsCreator.count') do
      assert_no_difference('@resource.creators.count') do
        @resource.update(params)
      end
    end

    assert_not_equal @resource.creators.first, creator
    assert_equal @resource.creators.first, new_creator
  end

  test 'removing a creator' do
    # Set creator
    creator = FactoryBot.create :person
    params = { creator_ids: [creator.id] }
    @resource.update(params)

    # Remove creator
    params = { creator_ids: [] }

    assert_difference('@resource.creators.count', -1) do
      assert_difference('AssetsCreator.count', -1) do
        @resource.update(params)
      end
    end
  end

  test 'changing multiple creators' do
    # Set creators
    creator_to_stay = FactoryBot.create :person
    creator_to_remove = FactoryBot.create :person
    params = { creator_ids: [creator_to_stay.id, creator_to_remove.id] }
    @resource.update(params)

    # Change creators
    new_creator = FactoryBot.create :person
    params = { creator_ids: [creator_to_stay.id, new_creator.id] }
    @resource.update(params)

    creators = @resource.creators
    assert_equal creators.count, 2
    assert creators.include?(creator_to_stay)
    assert creators.include?(new_creator)
    assert !creators.include?(creator_to_remove)
  end

  test 'cannot add duplicate assets creators by creator_id' do
    disable_authorization_checks do
      assert_no_difference('AssetsCreator.count') do
        @sop.update(assets_creators_attributes: {
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
        @sop.update(assets_creators_attributes: {
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
        @sop.update(assets_creators_attributes: {
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
        @sop.update(assets_creators_attributes: {
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
    other_sop = FactoryBot.create(:sop)

    disable_authorization_checks do
      assert_difference('AssetsCreator.count', 1) do
        other_sop.update(assets_creators_attributes: {
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

  test 'automatically links to creator based on orcid' do
    explicitly_linked_person = FactoryBot.create(:person, first_name: 'Link', orcid: 'https://orcid.org/0000-0002-5111-7263')
    orcid_linked_person = FactoryBot.create(:person_not_in_project, first_name: 'Orc', orcid: 'https://orcid.org/0000-0002-1825-0097')
    should_not_be_linked = FactoryBot.create(:person_not_in_project, orcid: 'https://orcid.org/0000-0001-9842-9718')

    sop = FactoryBot.create(:sop)

    disable_authorization_checks do
      assert_difference('AssetsCreator.count', 2) do
        sop.update(assets_creators_attributes: {
          '4634' => {
            orcid: 'https://orcid.org/0000-0001-9842-9718',
            creator_id: explicitly_linked_person.id
          },
          '123' => {
            orcid: 'https://orcid.org/0000-0002-1825-0097'
          }
        })

        ac = sop.reload.assets_creators.to_a
        assert_equal 2, ac.length
        assert_equal orcid_linked_person, ac.detect { |a| a.given_name == 'Orc' }.creator
        assert_equal explicitly_linked_person, ac.detect { |a| a.given_name == 'Link' }.creator,
                     'If creator is explicitly set, it should not attempt to link a different creator via orcid'
      end
    end
  end
end
