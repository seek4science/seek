# To change this template, choose Tools | Templates
# and open the template in the editor.

class InstitutionsSweeper < ActionController::Caching::Sweeper

  include CommonSweepers

  observe Institution

  def before_save(i)
    if (i.changed.include?("avatar_id"))
      expire_all_favourite_fragments
    end
  end

  def after_create(i)

  end

  def after_update(i)

  end

  def after_destroy(i)

  end

  private


end