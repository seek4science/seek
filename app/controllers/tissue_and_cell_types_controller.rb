class TissueAndCellTypesController < ApplicationController



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