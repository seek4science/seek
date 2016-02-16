class SampleTypesController < ApplicationController
  # GET /sample_types
  # GET /sample_types.json
  def index
    @sample_types = SampleType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sample_types }
    end
  end

  # GET /sample_types/1
  # GET /sample_types/1.json
  def show
    @sample_type = SampleType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sample_type }
    end
  end

  # GET /sample_types/new
  # GET /sample_types/new.json
  def new
    @sample_type = SampleType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sample_type }
    end
  end

  # GET /sample_types/1/edit
  def edit
    @sample_type = SampleType.find(params[:id])
  end

  # POST /sample_types
  # POST /sample_types.json
  def create
    @sample_type = SampleType.new(params[:sample_type])

    respond_to do |format|
      if @sample_type.save
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully created.' }
        format.json { render json: @sample_type, status: :created, location: @sample_type }
      else
        format.html { render action: "new" }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sample_types/1
  # PUT /sample_types/1.json
  def update
    @sample_type = SampleType.find(params[:id])

    respond_to do |format|
      if @sample_type.update_attributes(params[:sample_type])
        format.html { redirect_to @sample_type, notice: 'Sample type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sample_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sample_types/1
  # DELETE /sample_types/1.json
  def destroy
    @sample_type = SampleType.find(params[:id])
    @sample_type.destroy

    respond_to do |format|
      format.html { redirect_to sample_types_url }
      format.json { head :no_content }
    end
  end
end
