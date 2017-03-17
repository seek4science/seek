require 'test_helper'

class FavouriteTest < ActiveSupport::TestCase
  fixtures :all

  test 'remove redundant' do
    fav = favourites(:data_file_fav)
    res = fav.resource
    assert_difference('Favourite.count', -1) do
      User.current_user = res.contributor
      res.destroy
    end

    o = Factory(:organism)
    fav = Favourite.new(resource: o, user: users(:quentin))
    fav.save!
    User.with_current_user Factory(:admin) do
      assert_difference('Favourite.count', -1) do
        o.destroy
      end
    end
  end

  test 'is_favouritable' do
    df = data_files(:picture)
    assert df.is_favouritable?
    assert DataFile.is_favouritable?

    assert Event.is_favouritable?
    assert events(:private_event).is_favouritable?

    o = organisms(:yeast)
    assert o.is_favouritable?
    assert Organism.is_favouritable?

    u = users(:quentin)
    assert !u.is_favouritable?
    assert !User.is_favouritable?

    assert SavedSearch.is_favouritable?
  end
end
