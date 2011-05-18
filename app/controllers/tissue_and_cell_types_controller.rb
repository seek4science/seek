class TissueAndCellTypesController < ApplicationController

  before_filter :find_and_auth,:only=>{:show_existing_tissue_and_cell_types,:index}

  def show_existing_tissue_and_cell_types
    element=params[:element]
    render :update do |page|
      page.replace_html element,:partial=>"tissue_and_cell_types/existing_tissue_and_cell_types",:object=>@tissue_and_cell_types
    end
  end

  def get_existing_tissue_and_cell_types
    @tissue_and_cell_types=TissueAndCellType.all
  end

  def show
    @tissue_and_cell_type=TissueAndCellType.find(params[:id])
    respond_to do |format|
      format.xml
    end
  end

  def index
    @tissue_and_cell_types = TissueAndCellType.all
    respond_to do |format|
      format.xml
    end
  end
end