class CultureGrowthTypesController < ApplicationController
  before_action :find_culture_growth_type

  def show
    respond_to do |format|
      format.all { render plain: @culture_growth_type.title }
      format.rdf { render template: 'rdf/show' }
    end
  end

  private

  def find_culture_growth_type
    @culture_growth_type = CultureGrowthType.find(params[:id])
  end
end
