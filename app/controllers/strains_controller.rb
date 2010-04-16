class StrainsController < ApplicationController

  before_filter :get_strains,:only=>:update_strain_tagging

  def update_strain_tagging
    element=params[:element]    
    render :update do |page|
      page.replace_html element,:partial=>"strains/strain_tagging"
    end
  end

  def get_strains
    if params[:organism_id]
      o=Organism.find_by_id(params[:organism_id])
      @strains=o.strains
    end
  end

end
