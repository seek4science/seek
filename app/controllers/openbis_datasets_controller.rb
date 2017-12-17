class OpenbisDatasetsController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  ALL_DATASETS = 'ALL DATASETS'.freeze

  def index
    puts "---\nINDEX\n#{params}"
    @dataset_type = params[:dataset_type] || ALL_DATASETS
    get_dataset_types

    #puts "---\nINDEX GET ENTITIES\n"
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

    reg_info = do_datafile_registration(@asset, {}, {})

    @datafile = reg_info[:datafile]
    issues = reg_info[:issues]

    unless @datafile
      @reasons = issues
      @error_msg = 'Could not register OpenBIS dataset'

      return render action: 'edit'
    end

    flash[:notice] = "Registered OpenBIS dataset: #{@entity.perm_id}"
    flash_issues(issues)
    redirect_to @datafile
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
      flash[:error] = 'Select datasets first';
      return back_to_index
    end

    unless seek_parent_id
      flash[:error] = 'Select parent assay for new elements';
      return back_to_index
    end

    status = batch_register_datasets(batch_ids, seek_parent_id)

    msg = "Registered all #{status[:registred].size} #{'datafile'.to_s.pluralize(status[:registred].size)}" if status[:failed].empty?
    msg = "Registered #{status[:registred].size} #{'datafile'.to_s.pluralize(status[:registred].size)} failed: #{status[:failed].size}" unless status[:failed].empty?
    flash[:notice] = msg;

    flash_issues(status[:issues])
    return back_to_index

  end

  def batch_register_datasets(dataset_ids, assay_id)

    sync_options = {}
    datafile_params = {}

    registered = []
    failed = []
    issues = []

    data_files = []

    assay = Assay.find(assay_id)
    dataset_ids.each do |id|

      get_entity(id)
      prepare_asset

      reg_info = do_datafile_registration(@asset, datafile_params, sync_options)
      if (reg_info[:datafile])
        registered << id
        data_files << reg_info[:datafile]
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join('; ') unless reg_info[:issues].empty?

    end

    unless data_files.empty?
      data_files.each { |df| assay.associate(df) }
    end

    return {registred: registered, failed: failed, issues: issues}

  end

  def do_datafile_registration(asset, datafile_params, sync_options)

    issues = []
    reg_status = {datafile: nil, issues: issues}

    if asset.seek_entity
      issues << 'Already registered as OpenBIS entity'
      return reg_status
    end

    asset.sync_options = sync_options

    # separate testing of external_asset as the save on parent does not fails if the child was not saved correctly
    unless asset.valid?
      issues.concat asset.errors.full_messages()
      return reg_status
    end

    datafile = seek_util.createObisDataFile(asset)

    if datafile.save
      reg_status[:datafile] = datafile
    else
      issues.concat datafile.errors.full_messages()
    end

    reg_status
  end

  def back_to_index
    index
    render action: 'index'
  end

  def get_entity(id = nil)
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, id ? id : params[:id])
  end

  def get_entities

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