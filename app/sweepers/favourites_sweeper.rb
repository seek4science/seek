class FavouritesSweeper < ActionController::Caching::Sweeper
  observe Favourite

  def after_create(fav)
    expire_cache(fav)
  end

  def after_update(fav)
    expire_cache(fav)
  end

  def after_destroy(fav)
    expire_cache(fav)
  end

  private

  def expire_cache(fav)
    id="favourites/user/#{fav.user.id}"
    puts "Expiring Favourites Cached for '#{id}'"
    expire_fragment(id)
  end
end