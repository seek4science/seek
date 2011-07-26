require 'white_list_helper'

class CountriesController < ApplicationController
  include WhiteListHelper

  # GET /countries/:country_name
  def show
    @country = white_list(params[:country_name])
    @institutions = Institution.find(:all, :conditions => ["country LIKE ?", @country])
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
end
