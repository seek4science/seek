class OpenbisZamplesController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  def index
    get_entities
  end


  def edit
    @assay = @asset.seek_entity || Assay.new
    @linked_to_assay = get_linked_to(@asset.seek_entity)
  end

  def register
    puts 'register called'
    puts params

    if @asset.seek_entity
      flash[:error] = 'Already registered as OpenBIS entity'
      return redirect_to @asset.seek_entity
    end

    @asset.sync_options = sync_options
    assay_params = params.require(:assay).permit(:study_id, :assay_class_id, :title)

    @assay = seek_util.createObisAssay(assay_params, current_person, @asset)

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

      flash[:notice] = "Registered OpenBIS assay: #{@entity.perm_id}"
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

    @assay = @asset.seek_entity

    unless @assay.is_a? Assay
      flash[:error] = 'Already registered Openbis entity but not as assay'
      return redirect_to @assay
    end

    # in case of rendering edit
    @linked_to_assay = get_linked_to(@asset.seek_entity)

    @asset.sync_options = sync_options
    @asset.content = @entity #or maybe we should not update, but that is what the user saw on the screen

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

    flash[:notice] = "Updated sync of OpenBIS assay: #{@entity.perm_id}"
    redirect_to @assay

  end

  def follow_dependent
    data_sets_ids = extract_requested_sets(@entity, params)
    return nil if data_sets_ids.empty?

    seek_util.associate_data_sets_ids(@assay, data_sets_ids, @openbis_endpoint)
  end




  def sync_options(hash = nil)
    hash ||= params
    hash.fetch(:sync_options, {}).permit(:link_datasets)
  end

  def extract_requested_sets(zample, params)
    return zample.dataset_ids if sync_options(params)[:link_datasets] == '1'

    (params[:linked_datasets] || []) & zample.dataset_ids
  end


  def get_linked_to(assay)
    return [] unless assay
    assay.data_files.select { |df| df.external_asset.is_a?(OpenbisExternalAsset) }
        .map { |df| df.external_asset.external_id }
  end


  def get_entity

    # sample = Seek::Openbis::Zample.new(@openbis_endpoint)
    # json = JSON.parse(
    #        '
    # {"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
    # "code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
    # "registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40","20171004182824553-41"]
    # ,"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
    # '
    #    )
    # @zample = sample.populate_from_json(json)

    @entity = Seek::Openbis::Zample.new(@openbis_endpoint, params[:id])
  end

  def get_entities
    @entities = Seek::Openbis::Zample.new(@openbis_endpoint).all
  end


end