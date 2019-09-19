class CountriesController < ApplicationController
  # GET /countries/:country_name
  def show
    country_code = CountryCodes.force_code(helpers.white_list(params[:country_code]))
    @country = CountryCodes.country(country_code)
    @institutions = if @country
                      Institution.where(country:country_code.upcase)
                    else
                      []
                    end


    # needed as @country is a unique case of being a string rather than instance of ActiveRecord
    @country.class_eval do
      def schema_org_supported?
        false
      end
    end
    
    respond_to do |format|
      if @country
        format.html
      else
        format.html { render 'errors/error_404',
                             layout: 'layouts/errors',
                             status: :not_found
        }
      end

    end
  end
end
