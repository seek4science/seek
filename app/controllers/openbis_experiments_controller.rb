class OpenbisExperimentsController < ApplicationController

  include Seek::Openbis::EntityControllerBase

  # before_filter :get_seek_type

  ALL_STUDIES = 'ALL STUDIES'.freeze
  ALL_TYPES = 'ALL TYPES'.freeze

  def index
    @entity_type = params[:entity_type] || ALL_STUDIES
    get_entity_types
    get_entities
  end


  def edit
    @study = @asset.seek_entity || Study.new
    @zamples_linked_to_study = get_zamples_linked_to(@asset.seek_entity)
    @datasets_linked_to_study = get_datasets_linked_to(@asset.seek_entity)
  end

  def register
    puts 'register called'
    puts params

    if @asset.seek_entity
      flash[:error] = 'Already registered as OpenBIS entity'
      return redirect_to @asset.seek_entity
    end

    sync_options = get_sync_options
    puts sync_options
    study_params = params.require(:study).permit(:investigation_id)

    reg_info = do_study_registration(@asset, study_params, sync_options, current_person, params)

    @study = reg_info[:study]
    issues = reg_info[:issues]

    unless @study
      @reasons = issues
      @error_msg = 'Could not register OpenBIS study'

      # for edit screen, always empty for new
      @zamples_linked_to_study = []
      @datasets_linked_to_study = []
      @study = Study.new
      return render action: 'edit'
    end

    flash[:notice] = "Registered OpenBIS Study: #{@entity.perm_id}#{issues.empty? ? '' : ' with some issues'}"
    flash_issues(issues)

    redirect_to @study
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

    errs = follow_assay_dependent(@asset.content, @assay, @asset.sync_options, params)
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
      when :assay then batch_register_assays(batch_ids, seek_parent_id)
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

    assay_params = {study_id: study_id}

    registered = []
    failed = []
    issues = []

    zample_ids.each do |id|

      get_entity(id)
      prepare_asset

      reg_info = do_assay_registration(@asset, assay_params, sync_options, current_person)
      if (reg_info[:assay])
        registered << id
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join('; ') unless reg_info[:issues].empty?

    end

    return {registred: registered, failed: failed, issues: issues}

  end

  def do_study_registration(asset, study_params, sync_options, creator, parameters = params)

    issues = []
    reg_status = {study: nil, issues: issues}

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

    study = seek_util.createObisStudy(study_params, creator, asset)

    if study.save
      errs = follow_study_dependent(asset.content, study, sync_options, parameters)
      issues.concat(errs) if errs
      reg_status[:study] = study
    else
      issues.concat study.errors.full_messages()
    end

    reg_status
  end


  def back_to_index
    index
    render action: 'index'
  end

  def follow_study_dependent(entity, study, sync_options, params)

    issues = []
    zamples_ids = extract_requested_zamples(entity, sync_options, params)

    issues.concat seek_util.associate_zamples_ids(study, zamples_ids, sync_options, entity.openbis_endpoint)

    # data_sets_ids = extract_requested_sets(entity, sync_options, params)
    # seek_util.associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)
    issues
  end


  def get_sync_options(hash = nil)
    hash ||= params
    hash.fetch(:sync_options, {}).permit(:link_datasets,:link_assays,:link_dependent)
  end

  def extract_requested_sets(zample, sync_options, params)
    return zample.dataset_ids if sync_options[:link_datasets] == '1'

    (params[:linked_datasets] || []) & zample.dataset_ids
  end

  def extract_requested_zamples(entity, sync_options, params)
    return entity.sample_ids if sync_options[:link_assays] == '1'

    (params[:linked_zamples] || []) & entity.sample_ids
  end


  def get_zamples_linked_to(study)
    return [] unless study
    #assay.data_files.select { |df| df.external_asset.is_a?(OpenbisExternalAsset) }
    #    .map { |df| df.external_asset.external_id }
    study.assays.select { |a| a.external_asset.is_a?(OpenbisExternalAsset)}
          .map{ |a| a.external_asset.external_id }
  end

  def get_datasets_linked_to(study)
    return [] unless study

    study.related_data_files.select { |df| df.external_asset.is_a?(OpenbisExternalAsset) }
        .map { |df| df.external_asset.external_id }
  end

  def get_entity(id = nil)
    @entity = Seek::Openbis::Experiment.new(@openbis_endpoint, id ? id : params[:id])
  end

  def get_entities
    if ALL_TYPES == @entity_type
      @entities = Seek::Openbis::Experiment.new(@openbis_endpoint).all
    else
      codes = @entity_type == ALL_STUDIES ? @entity_types_codes : [@entity_type]
      @entities = Seek::Openbis::Experiment.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def get_entity_types
    get_study_types
  end

  def get_study_types
    @entity_types = seek_util.study_types(@openbis_endpoint)
    @entity_types_codes = @entity_types.map { |t| t.code }
    @entity_type_options = @entity_types_codes + [ALL_STUDIES, ALL_TYPES]
  end


end