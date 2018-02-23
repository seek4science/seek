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

    reg_info = do_study_registration(@asset, study_params, sync_options, current_person)

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

    @study = @asset.seek_entity

    unless @study.is_a? Study
      flash[:error] = 'Already registered Openbis entity but not as study'
      return redirect_to @study
    end


    @asset.sync_options = get_sync_options
    @asset.content = @entity #or maybe we should not update, but that is what the user saw on the screen

    # separate saving of external_asset as the save on parent does not fails if the child was not saved correctly
    unless @asset.save
      @reasons = @asset.errors
      @error_msg = 'Could not update sync of OpenBIS study'

      # for edit screen
      @zamples_linked_to_study = get_zamples_linked_to(@asset.seek_entity)
      @datasets_linked_to_study = get_datasets_linked_to(@asset.seek_entity)
      return render action: 'edit'
    end

    errs = follow_study_dependent(@asset.content, @study, @asset.sync_options)

    flash_issues(errs)
    # TODO should the assay be saved as well???

    flash[:notice] = "Updated sync of OpenBIS study: #{@entity.perm_id}"
    redirect_to @study

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

    status = batch_register_studies(batch_ids, seek_parent_id)

    seek_type = Study

    msg = "Registered all #{status[:registred].size} #{seek_type.to_s.pluralize(status[:registred].size)}" if status[:failed].empty?
    msg = "Registered #{status[:registred].size} #{seek_type.to_s.pluralize(status[:registred].size)} failed: #{status[:failed].size}" unless status[:failed].empty?
    flash[:notice] = msg;
    flash_issues(status[:issues])

    return back_to_index

  end

  def batch_register_studies(experiment_ids, investigation_id)

    sync_options = get_sync_options
    puts "SYNC OPT #{sync_options}"
    sync_options[:link_datasets] = '1' if sync_options[:link_dependent] == '1'
    sync_options[:link_assays] = '1' if sync_options[:link_dependent] == '1'

    study_params = { investigation_id: investigation_id }

    registered = []
    failed = []
    issues = []

    experiment_ids.each do |id|

      get_entity(id)
      prepare_asset

      reg_info = do_study_registration(@asset, study_params, sync_options, current_person)
      if reg_info[:study]
        registered << id
      else
        failed << id
      end
      issues << "Openbis #{id}: " + reg_info[:issues].join('; ') unless reg_info[:issues].empty?

    end

    { registred: registered, failed: failed, issues: issues }

  end

  def do_study_registration(asset, study_params, sync_options, creator)

    issues = []
    reg_status = { study: nil, issues: issues }

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
      errs = follow_study_dependent(asset.content, study, sync_options)
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

  def follow_study_dependent(entity, study, sync_options)

    issues = []

    issues.concat follow_dependent_assays(entity, study, sync_options)

    # data_sets_ids = extract_requested_sets(entity, sync_options, params)
    # seek_util.associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)
    issues
  end

  def follow_dependent_assays(entity, study, sync_options)

    zamples = seek_util.extract_requested_assays(entity, sync_options)

    assay_sync = seek_util.simplify_assay_sync(sync_options)
    seek_util.associate_zamples_as_assays(study, zamples, assay_sync)

  end




  def get_sync_options(hash = nil)
    hash ||= params
    hash.fetch(:sync_options, {}).permit(:link_datasets, :link_assays, :link_dependent,
                                         {linked_datasets: []}, {linked_assays: []})
  end






  def get_zamples_linked_to(study)
    return [] unless study

    study.assays.select { |a| a.external_asset.is_a?(OpenbisExternalAsset) }
        .map { |a| a.external_asset.external_id }
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