class OpenbisZamplesController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  before_filter :get_seek_type
  before_filter :get_zample_types, only: [:index]

  ALL_ASSAYS = 'ALL ASSAYS'.freeze
  ALL_TYPES = 'ALL TYPES'.freeze

  def index
    @zample_type = params[:zample_type] || ALL_ASSAYS
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

    @asset.sync_options = get_sync_options
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

    @asset.sync_options = get_sync_options
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

  def batch_register_assays(zample_ids, study_id)

    sync_options = get_sync_options
    sync_options[:link_datasets] = '1' if sync_options[:link_dependent]

    assay_params = {study_id: study_id}

    registered = []
    failed = []
    issues = []

    zample_ids.each do |id|

      get_entity(id)
      prepare_asset

      reg_info = do_assay_registration(@asset, assay_params, sync_options)
      if (reg_info[:assay])
        registered << id
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join(', ') if reg_info[:issues]

    end

    return {registred: registered, failed: failed, issues: issues}

  end

  def do_assay_registration(asset, assay_params, sync_options)

    issues = []
    reg_status = {assay: nil, issues: issues}

    if asset.seek_entity
      issues << 'Already registered as OpenBIS entity'
      return reg_status
    end

    asset.sync_options = sync_options

    assay = seek_util.createObisAssay(assay_params, current_person, asset)

    # separate testing of external_asset as the save on parent does not fails if the child was not saved correctly
    unless asset.valid?
      issues.concat asset.errors.full_messages()
      return reg_status
    end

    if assay.save

      errs = follow_assay_dependent(asset.content, assay, sync_options, {})
      issues.concat(errs) if errs

      reg_status[:assay] = assay
    else
      issues.concat assay.errors.full_messages()
    end

    return reg_status
  end


  def back_to_index
    get_zample_types
    index;
    render action: 'index'
  end

  def follow_assay_dependent(entity, assay, sync_options, params)
    data_sets_ids = extract_requested_sets(entity, sync_options, params)
    return nil if data_sets_ids.empty?

    seek_util.associate_data_sets_ids(assay, data_sets_ids, @openbis_endpoint)
  end


  def get_sync_options(hash = nil)
    hash ||= params
    hash.fetch(:sync_options, {}).permit(:link_datasets,:link_dependent)
  end

  def extract_requested_sets(zample, sync_options, params)
    return zample.dataset_ids if sync_options[:link_datasets] == '1'

    (params[:linked_datasets] || []) & zample.dataset_ids
  end


  def get_linked_to(assay)
    return [] unless assay
    assay.data_files.select { |df| df.external_asset.is_a?(OpenbisExternalAsset) }
        .map { |df| df.external_asset.external_id }
  end


  def get_entity(id = nil)

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

    @entity = Seek::Openbis::Zample.new(@openbis_endpoint, id ? id : params[:id])
  end

  def get_entities
    if ALL_TYPES == @zample_type
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).all
    else
      codes = @zample_type == ALL_ASSAYS ? @zample_types_codes : [@zample_type]
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def get_zample_types
    case @seek_type
      when :assay then get_assay_types
      else raise "Don't recognize obis types for seek: #{@seek_type}"
    end
  end

  def get_assay_types
    @zample_types = seek_util.assay_types(@openbis_endpoint)
    @zample_types_codes = @zample_types.map { |t| t.code }
    @zample_type_options = @zample_types_codes + [ALL_ASSAYS, ALL_TYPES]
  end

  def get_seek_type
    type = params[:seek] || 'empty'
    @seek_type = type.to_sym
  end
end