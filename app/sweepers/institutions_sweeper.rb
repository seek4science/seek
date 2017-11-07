# To change this template, choose Tools | Templates
# and open the template in the editor.

class InstitutionsSweeper < ActionController::Caching::Sweeper
  include CommonSweepers

  observe Institution

  def before_save(i)
    expire_all_favourite_fragments if i.changed.include?('avatar_id')
  end

  def after_create(i); end

  def after_update(i); end

  def after_destroy(i); end

  private
end
