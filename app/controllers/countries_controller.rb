class CountriesController < ApplicationController
  include WhiteListHelper

  # GET /countries/:country_name
  def show
    @country = white_list(params[:country_name])
    @institutions = Institution.where(["country LIKE ?", @country])

    # needed as @country is a unique case of being a string rather than instance of ActiveRecord
    @country.class_eval do
      def schema_org_supported?
        false
      end
    end
    
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
