class SampleAttributeTypesController < ApplicationController

  respond_to :json

  api_actions :index

  def index
    respond_to do |format|
      format.json {render json: SampleAttributeType.all}
    end
  end

  def show
    respond_to do |format|
      format.json {render json: SampleAttributeType.find(params["id"])}
    end
  end
end
