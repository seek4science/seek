class ChangeFavouriteGroupNames < ActiveRecord::Migration[6.1]
  def up
    FavouriteGroup.where(name: '__blacklist__').update_all(name: '__denylist__')
    FavouriteGroup.where(name: '__whitelist__').update_all(name: '__allowlist__')
  end

  def down
    FavouriteGroup.where(name: '__denylist__').update_all(name: '__blacklist__')
    FavouriteGroup.where(name: '__allowlist__').update_all(name: '__whitelist__')
  end
end
