class StatisticsController < ApplicationController
  before_action :is_user_admin_auth, only: [:index]

  def index; end

  def application_status
    respond_to do |format|
      format.html { render formats: [:text] }
    end
  end
end
