class FavouritesController < ApplicationController
  before_action :login_required

  cache_sweeper :favourites_sweeper, only: %i[add delete]

  def add
    if params[:resource_type] == 'SavedSearch' # needs to create the SavedSearch resource first
      saved_search = SavedSearch.new(user_id: current_user.id,
                                     search_query: params[:search_query],
                                     search_type: params[:search_type],
                                     include_external_search: params[:include_external_search] == '1')

      resource = saved_search if saved_search.save
    else
      resource = safe_class_lookup(params[:resource_type]).find_by_id(params[:resource_id])
    end

    favourite = Favourite.new(user: current_user, resource: resource)

    if resource && resource.is_favouritable? && favourite.save
      render partial: 'favourites/gadget_list', status: :created
    else
      head :unprocessable_entity
    end
  end

  def delete
    f = Favourite.find(params[:id])

    if f.user == current_user && f.destroy
      render partial: 'favourites/gadget_list'
    else
      head :unprocessable_entity
    end
  end
end
