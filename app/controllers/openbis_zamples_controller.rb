class OpenbisZamplesController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  before_filter :get_seek_type

  def index
    @entity_type = params[:entity_type] || Seek::Openbis::ALL_ASSAYS
    get_entity_types
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

    sync_options = get_sync_options
    assay_params = params.require(:assay).permit(:study_id, :assay_class_id, :title)

    reg_info = do_assay_registration(@asset, assay_params, sync_options, current_person)

    @assay = reg_info[:assay]
    issues = reg_info[:issues]

    unless @assay
      @reasons = issues
      @error_msg = 'Could not register OpenBIS assay'

      # for edit screen
      @linked_to_assay = get_linked_to(@asset.seek_entity)
      @assay = Assay.new
      return render action: 'edit'
    end

    flash[:notice] = "Registered OpenBIS assay: #{@entity.perm_id}#{issues.empty? ? '' : ' with some issues'}"
    flash_issues(issues)

    redirect_to @assay
  end

  def update
    puts 'update called'
    puts params

    @assay = @asset.seek_entity

    unless @assay.is_a? Assay
      flash[:error] = 'Already registered Openbis entity but not as assay'
      return redirect_to @assay
    end


    @asset.sync_options = get_sync_options
    @asset.content = @entity #or maybe we should not update, but that is what the user saw on the screen

    # separate saving of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.save
      @reasons = @asset.errors
      @error_msg = 'Could not update sync of OpenBIS assay'

      # for edit screen
      @linked_to_assay = get_linked_to(@asset.seek_entity)
      return render action: 'edit'
    end

    errs = seek_util.follow_assay_dependent(@assay)
    flash_issues(errs)
    # TODO should the assay be saved as well???

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
               when :assay then
                 batch_register_assays(batch_ids, seek_parent_id)
             end

    msg = "Registered all #{status[:registred].size} #{@seek_type.to_s.pluralize(status[:registred].size)}" if status[:failed].empty?
    msg = "Registered #{status[:registred].size} #{@seek_type.to_s.pluralize(status[:registred].size)} failed: #{status[:failed].size}" unless status[:failed].empty?
    flash[:notice] = msg;
    flash_issues(status[:issues])

    return back_to_index

  end

  def batch_register_assays(zample_ids, study_id)

    sync_options = get_sync_options
    puts "SYNC OPT #{sync_options}"
    sync_options[:link_datasets] = '1' if sync_options[:link_dependent] == '1'

    assay_params = { study_id: study_id }

    registered = []
    failed = []
    issues = []

    zample_ids.each do |id|

      get_entity(id)
      prepare_asset

      # params must be clones so not to be shared
      reg_info = do_assay_registration(@asset, assay_params.clone, sync_options, current_person)
      if (reg_info[:assay])
        registered << id
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join('; ') unless reg_info[:issues].empty?

    end

    return { registred: registered, failed: failed, issues: issues }

  end

  def do_assay_registration(asset, assay_params, sync_options, creator)

    issues = []
    reg_status = { assay: nil, issues: issues }

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

    assay = seek_util.createObisAssay(assay_params, creator, asset)

    if assay.save
      errs = seek_util.follow_assay_dependent(assay)
      issues.concat(errs) if errs
      reg_status[:assay] = assay
    else
      issues.concat assay.errors.full_messages()
    end

    reg_status
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
    if Seek::Openbis::ALL_TYPES == @entity_type
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).all
    else
      codes = @entity_type == Seek::Openbis::ALL_ASSAYS ? @entity_types_codes : [@entity_type]
      puts "FIND CODES: #{codes}"
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def get_entity_types
    case @seek_type
      when :assay then
        get_assay_types
      else
        raise "Don't recognized obis types for seek: #{@seek_type}"
    end
  end


  def get_assay_types
    @entity_types = seek_util.assay_types(@openbis_endpoint)
    @entity_types_codes = @entity_types.map { |t| t.code }
    @entity_type_options = @entity_types_codes + [Seek::Openbis::ALL_ASSAYS, Seek::Openbis::ALL_TYPES]
  end

  def get_seek_type
    type = params[:seek] || :assay
    @seek_type = type.to_sym
  end
end