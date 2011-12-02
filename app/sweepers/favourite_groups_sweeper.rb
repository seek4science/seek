class FavouriteGroupsSweeper < ActionController::Caching::Sweeper
  observe FavouriteGroup

  def after_update(fg)
    fg.permissions.each &:touch
  end
end