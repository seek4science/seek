class SampleAttributeTypesController < ApplicationController
  # GET /sample_attribute_types
  # GET /sample_attribute_types.json
  def index
    @sample_attribute_types = SampleAttributeType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sample_attribute_types }
    end
  end

  # GET /sample_attribute_types/1
  # GET /sample_attribute_types/1.json
  def show
    @sample_attribute_type = SampleAttributeType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sample_attribute_type }
    end
  end

  # GET /sample_attribute_types/new
  # GET /sample_attribute_types/new.json
  def new
    @sample_attribute_type = SampleAttributeType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sample_attribute_type }
    end
  end

  # GET /sample_attribute_types/1/edit
  def edit
    @sample_attribute_type = SampleAttributeType.find(params[:id])
  end

  # POST /sample_attribute_types
  # POST /sample_attribute_types.json
  def create
    @sample_attribute_type = SampleAttributeType.new(params[:sample_attribute_type])

    respond_to do |format|
      if @sample_attribute_type.save
        format.html { redirect_to @sample_attribute_type, notice: 'Sample attribute type was successfully created.' }
        format.json { render json: @sample_attribute_type, status: :created, location: @sample_attribute_type }
      else
        format.html { render action: "new" }
        format.json { render json: @sample_attribute_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sample_attribute_types/1
  # PUT /sample_attribute_types/1.json
  def update
    @sample_attribute_type = SampleAttributeType.find(params[:id])

    respond_to do |format|
      if @sample_attribute_type.update_attributes(params[:sample_attribute_type])
        format.html { redirect_to @sample_attribute_type, notice: 'Sample attribute type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sample_attribute_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sample_attribute_types/1
  # DELETE /sample_attribute_types/1.json
  def destroy
    @sample_attribute_type = SampleAttributeType.find(params[:id])
    @sample_attribute_type.destroy

    respond_to do |format|
      format.html { redirect_to sample_attribute_types_url }
      format.json { head :no_content }
    end
  end
end
