class CountriesController < ApplicationController
  # GET /countries/:country_name
  def show
    country_code = CountryCodes.force_code(helpers.sanitized_text(params[:country_code]))
    @country = CountryCodes.country(country_code)
    @institutions = if @country
                      Institution.where(country:country_code.upcase)
                    else
                      []
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
