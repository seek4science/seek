class HomeController < ApplicationController
  
  before_filter :login_required
  
  layout :select_layout
  
  def index
    respond_to do |format|
      format.html # index.html.erb      
    end
  end
  
  def select_layout
    if logged_in?
      return 'main'
    else
      return 'logged_out'
    end
  end
end
