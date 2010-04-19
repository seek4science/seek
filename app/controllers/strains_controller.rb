class StrainsController < ApplicationController

  before_filter :get_strains,:only=>:show_existing_strains

  def show_existing_strains
    element=params[:element]    
    render :update do |page|
      page.replace_html element,:partial=>"strains/existing_strains",:object=>@strains
    end
  end

  def get_strains
    if params[:organism_id]
      o=Organism.find_by_id(params[:organism_id])
      @strains=o.strains
    end
  end

end
