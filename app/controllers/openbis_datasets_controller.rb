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

    if @asset.seek_entity
      flash[:error] = 'Already registered as OpenBIS entity'
      return redirect_to @asset.seek_entity
    end


    @datafile = seek_util.createObisDataFile(@asset)

    if @datafile.save

      flash[:notice] = "Registered OpenBIS dataset: #{@entity.perm_id}"
      redirect_to @datafile
    else
      @reasons = @datafile.errors
      @error_msg = 'Could not register OpenBIS dataset'
      render action: 'edit'
    end
  end

  def update
    puts 'update called'
    puts params

    @datafile = @asset.seek_entity

    unless @datafile.is_a? DataFile
      flash[:error] = 'Already registered Openbis entity but not as datafile'
      return redirect_to @datafile
    end

    @asset.content = @entity #or maybe we should not update, but that is what the user saw on the screen

    # separate saving of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.save
      @reasons = @asset.errors
      @error_msg = 'Could not update sync of OpenBIS datafile'
      return render action: 'edit'
    end


    # TODO should the datafile be saved as well???


    flash[:notice] = "Updated sync of OpenBIS datafile: #{@entity.perm_id}"
    redirect_to @datafile

  end



  def get_entity
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, params[:id])
  end

  def get_entities
    @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all
  end

end