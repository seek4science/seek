
# Controller that handles registration/display of OpenBIS datasets as DataFile
class OpenbisDatasetsController < ApplicationController
  include Seek::Openbis::EntityControllerBase

  # it was like this in Stuart code, but if one can see the dataset why it should not see list
  # of its files even if it was registered as another private DataFile?
  # before_filter :authorise_show_dataset_files, only: [:show_dataset_files]

  def index
    puts "---\nINDEX\n#{params}" if DEBUG
    @entity_type = params[:entity_type] || Seek::Openbis::ALL_DATASETS
    get_entity_types
    get_entities
  end

  def edit
    @datafile = @asset.seek_entity || DataFile.new
  end

  def register
    puts 'register called' if DEBUG
    puts params if DEBUG

    if @asset.seek_entity
      flash[:error] = 'Already registered as OpenBIS entity'
      return redirect_to @asset.seek_entity
    end

    sync_options = {} # no options for dataset get_sync_options
    datafile_params = params.fetch(:data_file, {}).permit(:assay_ids)

    reg_info = do_datafile_registration(@asset, datafile_params, sync_options, current_person)

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
    puts 'update called' if DEBUG
    puts params if DEBUG

    @datafile = @asset.seek_entity

    unless @datafile.is_a? DataFile
      flash[:error] = 'Already registered Openbis entity but not as datafile'
      return redirect_to @datafile
    end

    # currently no sync options
    # @asset.sync_options = get_sync_options
    @asset.content = @entity # or maybe we should not update, but that is what the user saw on the screen

    # separate saving of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.save
      @reasons = @asset.errors
      @error_msg = 'Could not update sync of OpenBIS datafile'
      return render action: 'edit'
    end

    # TODO: should the datafile be saved as well???

    flash[:notice] = "Updated sync of OpenBIS datafile: #{@entity.perm_id}"
    redirect_to @datafile
  end

  def batch_register
    batch_ids = params[:batch_ids] || []
    seek_parent_id = params[:seek_parent]

    if batch_ids.empty?
      flash[:error] = 'Select datasets first'
      return back_to_index
    end

    unless seek_parent_id
      flash[:error] = 'Select parent assay for new elements'
      return back_to_index
    end

    status = batch_register_datasets(batch_ids, seek_parent_id)

    msg = "Registered all #{status[:registred].size} #{'datafile'.to_s.pluralize(status[:registred].size)}" if status[:failed].empty?
    msg = "Registered #{status[:registred].size} #{'datafile'.to_s.pluralize(status[:registred].size)} failed: #{status[:failed].size}" unless status[:failed].empty?
    flash[:notice] = msg

    flash_issues(status[:issues])
    back_to_index
  end

  def batch_register_datasets(dataset_ids, assay_id)
    sync_options = {} # currently always empty
    datafile_params = { assay_ids: assay_id }

    registered = []
    failed = []
    issues = []

    dataset_ids.each do |id|
      get_entity(id)
      prepare_asset

      # have to clone params so the titles and such won't be overwritten
      reg_info = do_datafile_registration(@asset, datafile_params.clone, sync_options, current_person)
      if reg_info[:datafile]
        registered << id
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join('; ') unless reg_info[:issues].empty?
    end

    #
    # unless data_files.empty?
    #  data_files.each { |df| assay.associate(df) }
    # end

    { registred: registered, failed: failed, issues: issues }
  end

  def do_datafile_registration(asset, datafile_params, sync_options, creator)
    issues = []
    reg_status = { datafile: nil, issues: issues }

    if asset.seek_entity
      issues << 'Already registered as OpenBIS entity'
      return reg_status
    end

    asset.sync_options = sync_options

    # separate testing of external_asset as the save on parent does not fails if the child was not saved correctly
    unless asset.valid?
      issues.concat asset.errors.full_messages
      return reg_status
    end

    datafile = seek_util.createObisDataFile(datafile_params, creator, asset)

    if datafile.save
      reg_status[:datafile] = datafile
    else
      issues.concat datafile.errors.full_messages
    end

    reg_status
  end

  def get_entity(id = nil)
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, id ? id : params[:id])
  end

  def get_entities
    if Seek::Openbis::ALL_DATASETS == @entity_type
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all
    else
      codes = [@entity_type]
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def get_entity_types
    get_dataset_types
  end

  def get_dataset_types
    @entity_types = seek_util.dataset_types(@openbis_endpoint)
    @entity_types_codes = @entity_types.map(&:code)
    @entity_type_options = @entity_types_codes + [Seek::Openbis::ALL_DATASETS]
  end

  ## AJAX calls

  def show_dataset_files
    respond_to do |format|
      format.html { render(partial: 'openbis_dataset_files_list', locals: { dataset: @entity, data_file: @asset.seek_entity }) }
    end
  end

  # TZ removed it, not sure about the logic behind it, if one can list data sets should be able to list their files
  # even if already registered as a DataFile
  # it only lists it does not download!!!

  # whether the dataset files can be shown. Depends on whether viewing a data file or now.
  #   # if data_file_id is present then the access controls on that data file is checked, otherwise needs to be a project member
  #   def authorise_show_dataset_files
  #     puts "\n\n\nENDPOINT CONTROLLER authorise_show_dataset_files"
  #
  #     @datafile = @asset.seek_entity
  #     if @data_file
  #       unless @data_file.can_download?
  #         error('DataFile cannot be accessed', 'No permission')
  #         return false
  #       end
  #     else
  #       project_member?
  #     end
  #   end
end
