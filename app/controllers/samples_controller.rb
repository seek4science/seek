class SamplesController < ApplicationController

  def new
    @sample = Sample.new(sample_type_id:params[:sample_type_id])
  end
end
