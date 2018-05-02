
# Controller that handles registration/display of OpenBIS datasets as DataFile
class OpenbisDatasetsController < ApplicationController
  include Seek::Openbis::EntityControllerBase

  # it was like this in Stuart code, but if one can see the dataset why it should not see list
  # of its files even if it was registered as another private DataFile?

  # before_filter :authorise_show_dataset_files, only: [:show_dataset_files]

  def seek_entity
    @datafile = @asset.seek_entity || DataFile.new
    @seek_entity = @datafile
  end

  def seek_params
    params.fetch(:data_file, {}).permit(:assay_ids)
  end

  def seek_params_for_batch
    { assay_ids: @seek_parent_id }
  end

  def create_seek_object_for_obis(seek_params, creator, asset)
    seek_util.createObisDataFile(seek_params, creator, asset)
  end

  def entity(id = nil)
    @entity = Seek::Openbis::Dataset.new(@openbis_endpoint, id ? id : params[:id])
  end

  def entities
    if Seek::Openbis::ALL_DATASETS == @entity_type
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).all
    else
      codes = [@entity_type]
      @entities = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def entity_type
    @entity_type = params[:entity_type] || Seek::Openbis::ALL_DATASETS
  end

  def entity_types
    dataset_types
  end

  def dataset_types
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
  # if data_file_id is present then the access controls on that data file is checked,
  # otherwise needs to be a project member
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
