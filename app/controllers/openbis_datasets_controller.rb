class OpenbisDatasetsController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  ALL_DATASETS = 'ALL DATASETS'.freeze

  def index
    @dataset_type = params[:dataset_type] || ALL_DATASETS
    get_dataset_types

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

  def batch_register
    puts params

    batch_ids = params[:batch_ids] || []
    seek_parent_id = params[:seek_parent]

    if batch_ids.empty?
      flash[:error] = 'Select entities first';
      return back_to_index
    end

    unless seek_parent_id
      flash[:error] = 'Select parent for new elements';
      return back_to_index
    end

    status = case @seek_type
               when :assay then batch_register_assays(batch_ids, seek_parent_id)
             end

    msg = "Registered all #{status[:registred].size} #{@seek_type.to_s.pluralize(status[:registred].size)}" if status[:failed].empty?
    msg = "Registered #{status[:registred].size} #{@seek_type.to_s.pluralize(status[:registred].size)} failed: #{status[:failed].size}" unless status[:failed].empty?
    flash[:notice] = msg;
    status[:issues].each {|m| flash[:error] = m}

    return back_to_index

  end

  def get_entity
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, params[:id])
  end

  def get_entities
    @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all

    if ALL_DATASETS == @dataset_type
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all
    else
      codes = [@dataset_type]
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def get_dataset_types
    @dataset_types = seek_util.dataset_types(@openbis_endpoint)
    @dataset_types_codes = @dataset_types.map { |t| t.code }
    @dataset_type_options = @dataset_types_codes + [ALL_DATASETS]
  end
end