class SamplesController < ApplicationController
  respond_to :html

  def new
    @sample = Sample.new(sample_type_id: params[:sample_type_id])
    respond_with(@sample)
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    @sample.read_attributes_from_params(params[:sample])
    flash[:notice] = 'The sample was successfully created.' if @sample.save
    respond_with(@sample)
  end

  def show
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def edit
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    @sample.update_attributes({:title=>params[:sample][:title]})
    @sample.read_attributes_from_params(params[:sample])
    flash[:notice] = 'The sample was successfully updated.' if @sample.save
    respond_with(@sample)
  end

end
