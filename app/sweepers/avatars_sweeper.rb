# To change this template, choose Tools | Templates
# and open the template in the editor.

class AvatarsSweeper < ActionController::Caching::Sweeper

  include CommonSweepers
  
  observe Avatar

  def after_create(avatar)
    expire_cache(avatar)
  end

  def after_update(avatar)
    expire_cache(avatar)
  end

  def after_destroy(avatar)
    expire_cache(avatar)
  end

  private

  def expire_cache(avatar)
    expire_all_favourite_fragments
  end
end
