class StatisticsController < ApplicationController

  def index
  end

  def application_status
    respond_to do |format|
      format.html {render :formats=>[:text]}
    end
  end

end
