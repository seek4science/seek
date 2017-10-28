class OpenbisDatasetsController < ApplicationController

  include Seek::Openbis::EntityControllerBase


  def index
    get_entities
  end


  def edit
    @datafile = @asset.seek_entity || DataFile.new
  end

  def register
    puts 'register called'
    puts params

    if OpenbisExternalAsset.registered?(@zample)
      flash[:error] = 'Already registered as OpenBIS entity'
      return redirect_to OpenbisExternalAsset.find_by_entity(@zample).seek_entity
    end


    #data_sets_ids = extract_requested_sets(@zample, params)
    #data_sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids(data_sets_ids)

    # data_files = find_or_register_seek_files(data_sets)

    assay_params = params.require(:assay).permit(:study_id, :assay_class_id, :title)

    @assay = seek_util.createObisAssay(assay_params, current_person, @zample, sync_options)
    @asset = @assay.external_asset
    # in case rendering edit on errors
    @linked_to_assay = []

    # seperate testing of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.valid?
      @reasons = @asset.errors
      @error_msg = 'Could not register OpenBIS assay'
      return render action: 'edit'
    end

    if @assay.save

      err = follow_dependent
      flash[:error] = err if err

      flash[:notice] = "Registered OpenBIS assay: #{@zample.perm_id}"
      redirect_to @assay
    else
      @reasons = @assay.errors
      @error_msg = 'Could not register OpenBIS assay'
      render action: 'edit'
    end
  end

  def update
    puts 'update called'
    puts params

    @asset = OpenbisExternalAsset.find_by_entity(@zample)
    @assay = @asset.seek_entity

    unless @assay.is_a? Assay
      flash[:error] = 'Already registered Openbis entity but not as assay'
      return redirect_to @assay
    end

    # in case of rendering edit
    @linked_to_assay = get_linked_to(@asset.seek_entity)


    puts "Sync: #{sync_options}"

    @asset.sync_options = sync_options
    @asset.content = @zample #or maybe we should not update, but that is what the user saw on the screen

    # separate saving of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.save
      @reasons = @asset.errors
      @error_msg = 'Could not update sync of OpenBIS assay'
      return render action: 'edit'
    end

    err = follow_dependent
    flash[:error] = err if err

    # TODO should the assay be saved as well???

    # if @assay.save
    #  flash[:notice] = "Registered OpenBIS assay: #{@zample.perm_id}"
    #  redirect_to @assay
    #else
    #  @reasons = @assay.errors
    #  @error_msg = 'Could not register OpenBIS assay'
    #  render action: 'edit'
    #end

    flash[:notice] = "Updated sync of OpenBIS assay: #{@zample.perm_id}"
    redirect_to @assay

  end



  def get_entity
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, params[:id])
  end

  def get_entities
    @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all
  end

end