class StudiesController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon
  include DynamicTableHelper

  before_action :studies_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[edit update destroy manage manage_update show new_object_based_on_existing_one]
  before_action :delete_linked_sample_types, only: [:destroy]

  # project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  # defined in the application controller
  before_action :project_membership_required_appended, only: [:new_object_based_on_existing_one]

  before_action :check_assays_are_not_already_associated_with_another_study, only: %i[create update]

  before_action :check_assays_are_for_this_study, only: %i[update]

  before_action :set_isa_json_compliance, only: :manage

  include Seek::Publishing::PublishingCommon
  include Seek::AnnotationCommon
  include Seek::ISAGraphExtensions

  api_actions :index, :show, :create, :update, :destroy

  def new_object_based_on_existing_one
    @existing_study = Study.find(params[:id])

    if @existing_study.can_view?
      @study = @existing_study.clone_with_associations
      unless @existing_study.investigation.can_edit?
        @study.investigation = nil
        flash.now[:notice] = "The #{t('investigation')} associated with the original #{t('study')} cannot be edited, so you need to select a different #{t('investigation')}"
      end
      render action: 'new'
    else
      flash[:error] = "You do not have the necessary permissions to copy this #{t('study')}"
      redirect_to study_path(@existing_study)
    end
  end

  def edit
    @study = Study.find(params[:id])
    if @study.is_isa_json_compliant?
      redirect_to edit_isa_study_path(@study)
    else
      respond_to do |format|
        format.html
      end
    end
  end

  def order_assays
    @study = Study.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @study = Study.find(params[:id])
    if params[:study]&.[](:ordered_assay_ids)
      a1 = params[:study][:ordered_assay_ids]
      a1.permit!
      pos = 0
      a1.each_pair do |key, value |
        disable_authorization_checks {
          assay = Assay.find (value)
          assay.position = pos
          pos += 1
          assay.save!
        }
      end
      respond_to do |format|
         format.html { redirect_to(@study) }
       end
    else
      @study.assign_attributes(study_params)
      update_sharing_policies @study
      update_annotations(params[:tag_list], @study)
      update_relationships(@study, params)

      respond_to do |format|
        if @study.save
          flash[:notice] = "#{t('study')} was successfully updated."
          format.html { redirect_to(@study) }
          format.json {render json: @study, include: [params[:include]]}
        else
          format.html { render action: 'edit', status: :unprocessable_entity }
          format.json { render json: json_api_errors(@study), status: :unprocessable_entity }
        end
      end
    end
  end

  def delete_linked_sample_types
    return unless @study.is_isa_json_compliant?
    return if @study.sample_types.empty?

    # The study sample types must be destroyed in reversed order
    # otherwise the first sample type won't be removed becaused it is linked from the second
    study_st_ids = @study.sample_types.map(&:id).sort { |a, b| b <=> a }
    SampleType.destroy(study_st_ids)
  end


  def show
    @study = Study.find(params[:id])

    respond_to do |format|
      format.html { render(params[:only_content] ? { layout: false } : {})}
      format.rdf { render template: 'rdf/show' }
      format.json {render json: @study, include: [params[:include]]}
    end
  end

  def create
    @study = Study.new(study_params)
    update_sharing_policies @study
    update_annotations(params[:tag_list], @study)
    update_relationships(@study, params)

    ### TO DO: what about validation of person responsible? is it already included (for json?)
    if @study.save
      respond_to do |format|
        flash[:notice] = "The #{t('study')} was successfully created.<br/>".html_safe
        format.html { redirect_to study_path(@study) }
        format.json { render json: @study, include: [params[:include]] }
      end
    else
      respond_to do |format|
        format.html { render action: 'new', status: :unprocessable_entity }
        format.json { render json: json_api_errors(@study), status: :unprocessable_entity }
      end
    end
  end

  def check_assays_are_for_this_study
    study_id = params[:id]
    if params[:study][:ordered_assay_ids]
      a1 = params[:study][:ordered_assay_ids]
      a1.permit!
      valid = true
      a1.each_pair do |key, value |
        a = Assay.find (value)
        valid = valid && !a.study.nil? && a.study_id.to_s == study_id
      end
      unless valid
        error("Each ordered #{t('assays.assay')} must be associated with the Study", "is invalid (invalid #{t('assays.assay')})")
        return false
      end
    end
    return true
  end

  def check_assays_are_not_already_associated_with_another_study
    assay_ids = params[:study][:assay_ids]
    study_id = params[:id]
    if assay_ids
      valid = !assay_ids.detect do |a_id|
        a = Assay.find(a_id)
        !a.study.nil? && a.study_id.to_s != study_id
      end
      unless valid
        unless valid
          error("Cannot add an #{t('assays.assay')} already associated with a Study", "is invalid (invalid #{t('assays.assay')})")
          return false
        end
      end
    end
  end

  def batch_uploader; end

  def preview_content
    if params.dig(:content_blobs, 0, :data).present?
      tempzip_path = params[:content_blobs][0][:data].tempfile.path
      data_files, studies = StudyBatchUpload.unzip_batch(tempzip_path)
      study_path = studies.first
      studies_file = ContentBlob.new
      studies_file.tmp_io_object = File.open(study_path)
      studies_file.original_filename = File.basename(study_path)
      studies_file.save!
      @studies = StudyBatchUpload.extract_studies_from_file(studies_file)
      @study = @studies[0]
      @studies_datafiles = StudyBatchUpload.extract_study_data_from_file(studies_file)
      @license = StudyBatchUpload.get_license_id(studies_file)
      @existing_studies = JSON.parse(StudyBatchUpload.get_existing_studies(@studies))

      render 'studies/batch_preview'

    else
      flash.now[:error] = 'Please select a file to upload or provide a URL to the data.'
      render 'studies/batch_uploader'
    end

  end

  def batch_create
    # create method will be called for each study
    # e.g: Study.new(title: 'title', investigation: investigations(:metabolomics_investigation), policy: FactoryBot.create(:private_policy))
    # study.policy = Policy.create(name: 'default policy', access_type: 1)
    # render plain: params[:studies].inspect
    metadata_types = ExtendedMetadataType.where(title: ExtendedMetadataType::MIAPPE_TITLE, supported_type: 'Study').last
    studies_length = params[:studies][:title].length
    studies_uploaded = false
    data_file_uploaded = false
    studies_length.times do |index|
      metadata = generate_metadata(params[:studies], index)
      study_params = {
        title: params[:studies][:title][index],
        description: params[:studies][:description][index],
        investigation_id: params[:study][:investigation_id],
        extended_metadata: ExtendedMetadata.new(
          extended_metadata_type: metadata_types,
          data: metadata
        )
      }
      @study = Study.new(study_params)
      missing_fields = StudyBatchUpload.check_study_is_MIAPPE_compliant(@study, metadata)
      if missing_fields.empty? && @study.valid? && @study.save! && @study.extended_metadata.valid?
        studies_uploaded = true if @study.save
      end
      data_file_uploaded = create_batch_assay_asset(params, index)
    end

    batch_uploaded = studies_uploaded && data_file_uploaded

    if batch_uploaded
      unless params[:existing_studies].blank?
        remove_existing_studies(params[:existing_studies])
      end
      FileUtils.rm_rf(StudyBatchUpload.upload_directory(User.current_user))
      respond_to do |format|
        flash[:notice] = "The #{t('study').pluralize} were successfully created.<br/>".html_safe
        format.html { redirect_to studies_path }
      end
    else
      respond_to do |format|
        flash[:error] = "Some #{t('study').pluralize} could not be created. Please check the data and try again."
        format.html { redirect_to batch_uploader_studies_path }
      end
    end
  end

  def create_batch_assay_asset(params, index)
    investigation = Investigation.find_by(id: params[:study][:investigation_id])
    return unless investigation

    assay_class = AssayClass.where(title: 'Experimental assay').first
    return unless assay_class

    data_file_names = params[:studies][:data_files][index].remove(' ').split(',')
    data_file_description = params[:studies][:data_file_description][index].remove(' ').split(',')
    license = params[:studies][:license]
    study_metadata_id = params[:studies][:id][index]
    data_file_path = StudyBatchUpload.upload_directory.join('data')

    data_file_names.each_with_index do |file_name, data_file_index|
      extended_metadata = ExtendedMetadata.where('json_metadata LIKE ?', "%\"id\":\"#{study_metadata_id}\"%").last
      next unless extended_metadata

      data_file_name = datafile_name_with_extension(file_name.to_s, data_file_path)
      next unless data_file_name

      assay = Assay.new(
        title: "Assay for #{study_metadata_id}-#{data_file_index + 1}",
        description: data_file_description[data_file_index],
        study_id: extended_metadata.item_id,
        assay_class: assay_class
      )
      next unless assay.save

      data_file_content_blob = ContentBlob.new
      data_file_content_blob.tmp_io_object = File.open(data_file_path.join(data_file_name))
      data_file_content_blob.original_filename = File.basename(data_file_name)

      data_file = DataFile.new(
        title: file_name,
        description: data_file_description[data_file_index],
        license: license,
        projects: investigation.projects,
        content_blob: data_file_content_blob
      )
      next unless data_file.save

      AssayAsset.create(assay: assay, asset: data_file)
    end

    true
  end

  def generate_metadata(studies_meta_data, index)
    metadata = {
      id: studies_meta_data[:id][index],
      study_start_date: studies_meta_data[:startDate][index],
      study_end_date: studies_meta_data[:endDate][index] || '',
      contact_institution: studies_meta_data[:contactInstitution][index],
      geographic_location_country: studies_meta_data[:geographicLocationCountry][index],
      experimental_site_name: studies_meta_data[:experimentalSiteName][index],
      latitude: studies_meta_data[:latitude][index],
      longitude: studies_meta_data[:longitude][index],
      altitude: studies_meta_data[:altitude][index],
      description_of_the_experimental_design: studies_meta_data[:descriptionOfTheExperimentalDesign][index],
      type_of_experimental_design: studies_meta_data[:typeOfExperimentalDesign][index],
      observation_unit_level_hierarchy: studies_meta_data[:observationUnitLevelHierarchy][index],
      observation_unit_description: studies_meta_data[:observationUnitDescription][index],
      description_of_growth_facility: studies_meta_data[:descriptionOfGrowthFacility][index],
      type_of_growth_facility: studies_meta_data[:typeOfGrowthFacility][index],
      cultural_practices: studies_meta_data[:culturalPractices][index]
    }
    metadata
  end

  def datafile_name_with_extension(file_name, path)
    files = Dir.entries(path)
    files.each do |file|
      if File.basename(file, '.*') == file_name
        return file
      elsif File.basename(file, '.*') == File.basename(file_name, '.*')
        return file
      end
    end

    nil
  end

  def remove_existing_studies(studies)
    JSON.parse(studies.to_json).each do |study_json|
      study = Study.find_by(id: JSON.parse(study_json)['id'])
      next unless study
      unless study.can_manage?
        flash[:error] = "Not authorized to replace #{t('study')} '#{study.title}'"
        next
      end
      AssayAsset.where(assay_id: study.assay_ids).destroy_all
      study.assays.each { |assay| assay.reload.destroy }
      study.reload.destroy
    end
  end

  private

  def set_isa_json_compliance
    @isa_json_compliant = @study.is_isa_json_compliant?
  end

  def study_params
    params.require(:study).permit(:title, :description, :experimentalists, :investigation_id,
                                  *creator_related_params, :position, { publication_ids: [] },
                                  { discussion_links_attributes:[:id, :url, :label, :_destroy] },
                                  { special_auth_codes_attributes: [:code, :expiration_date, :id, :_destroy] },
                                  { extended_metadata_attributes: determine_extended_metadata_keys })
  end
end
