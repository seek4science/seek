require 'test_helper'

class FavouriteTest < ActiveSupport::TestCase

  test 'remove redundant' do
    fav = favourites(:data_file_fav)
    res = fav.resource
    assert_difference('Favourite.count', -1) do
      User.current_user = res.contributor
      res.destroy
    end

    o = FactoryBot.create(:organism)
    fav = Favourite.new(resource: o, user: users(:quentin))
    fav.save!
    User.with_current_user FactoryBot.create(:admin) do
      assert_difference('Favourite.count', -1) do
        o.destroy
      end
    end
  end

  test 'is_favouritable?' do

    assert FactoryBot.create(:data_file).is_favouritable?
    assert DataFile.is_favouritable?

    assert FactoryBot.create(:event).is_favouritable?
    assert Event.is_favouritable?

    assert FactoryBot.create(:organism).is_favouritable?
    assert Organism.is_favouritable?

    assert FactoryBot.create(:workflow).is_favouritable?
    assert Workflow.is_favouritable?

    refute FactoryBot.create(:user).is_favouritable?
    refute User.is_favouritable?

    assert SavedSearch.is_favouritable?

    # versions
    assert FactoryBot.create(:data_file_version).is_favouritable?
    assert DataFile::Version.is_favouritable?

    assert FactoryBot.create(:workflow_version).is_favouritable?
    assert Workflow::Version.is_favouritable?

    assert FactoryBot.create(:workflow_version).is_favouritable?
    assert Workflow::Version.is_favouritable?

    assert FactoryBot.create(:git_version).is_favouritable?
    assert Git::Version.is_favouritable?

    wfv = FactoryBot.create(:git_version).becomes(Workflow::Git::Version)
    assert wfv.is_favouritable?
    assert Workflow::Git::Version.is_favouritable?


  end
end
