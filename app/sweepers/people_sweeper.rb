# To change this template, choose Tools | Templates
# and open the template in the editor.

class PeopleSweeper < ActionController::Caching::Sweeper

  include CommonSweepers

  observe Person

  def before_save(p)
    if (p.changed.include?("avatar_id"))
      expire_all_favourite_fragments
    end
  end

  def after_create(p)

  end

  def after_update(p)

  end

  def after_destroy(p)

  end

  private


end
