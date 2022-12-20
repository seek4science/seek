class CookiesController < ApplicationController
    #skip_before_action :authen!, :authenticate_user_from_token!
    before_action :set_cookie_consent_object
  
    def consent
      respond_to do |format|
        format.html
      end
    end
  
    def set_consent
      @cookie_consent.options = cookie_params[:allow]
      
      flash[:error] = 'Invalid cookie consent option provided' unless @cookie_consent.options.any?
  
      respond_to do |format|
        format.html { redirect_back(fallback_location: cookies_consent_path) }
      end
    end
  
    private
  
    def set_cookie_consent_object
      @cookie_consent = CookieConsent.new(cookies)
    end
  
    def cookie_params
      params.permit(:allow)
    end
  end  