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
    ActionController::Base.new.expire_fragment("favourites/user/#{fav.user.try(:id)}")
  end
end