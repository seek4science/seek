class StatisticsController < ApplicationController

  def index
  end

  def application_status
    respond_to do |format|
      format.html {render :layout=>false}
    end
  end

end
