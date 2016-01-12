class DataSharePacksController < ApplicationController
  # GET /data_share_packs
  # GET /data_share_packs.json
  def index
    @data_share_packs = DataSharePack.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @data_share_packs }
    end
  end

  # GET /data_share_packs/1
  # GET /data_share_packs/1.json
  def show
    @data_share_pack = DataSharePack.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @data_share_pack }
    end
  end

  # GET /data_share_packs/new
  # GET /data_share_packs/new.json
  def new
    @assay =  Assay.find(1)
    #@assay =  Assay.find(params[:id])
    @data_share_pack = DataSharePack.new
    @data_share_pack.title = @assay.title
    @data_share_pack.description = @assay.description


    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @data_share_pack }
    end
  end

  # GET /data_share_packs/1/edit
  def edit
    @data_share_pack = DataSharePack.find(params[:id])
  end

  # POST /data_share_packs
  # POST /data_share_packs.json
  def create
    @data_share_pack = DataSharePack.new(params[:data_share_pack])

    respond_to do |format|
      if @data_share_pack.save
        format.html { redirect_to @data_share_pack, notice: 'Data share pack was successfully created.' }
        format.json { render json: @data_share_pack, status: :created, location: @data_share_pack }
      else
        format.html { render action: "new" }
        format.json { render json: @data_share_pack.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /data_share_packs/1
  # PUT /data_share_packs/1.json
  def update
    @data_share_pack = DataSharePack.find(params[:id])

    respond_to do |format|
      if @data_share_pack.update_attributes(params[:data_share_pack])
        format.html { redirect_to @data_share_pack, notice: 'Data share pack was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @data_share_pack.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data_share_packs/1
  # DELETE /data_share_packs/1.json
  def destroy
    @data_share_pack = DataSharePack.find(params[:id])
    @data_share_pack.destroy

    respond_to do |format|
      format.html { redirect_to data_share_packs_url }
      format.json { head :no_content }
    end
  end
end
