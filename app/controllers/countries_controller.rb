class CountriesController < ApplicationController
  include WhiteListHelper

  # GET /countries/:country_name
  def show
    @country = white_list(params[:country_name])
    @institutions = Institution.where(["country LIKE ?", @country])
    
    respond_to do |format|
      if Seek::Config.is_virtualliver
        unless current_user
          format.html # show.html.erb
        else
          store_return_to_location
          flash[:error] = "You are not authorized to view institutions and people in this country, you may need to login first."
          format.html { redirect_to home_url}
        end
      else
        format.html # show.html.erb
      end
    end
  end
end
