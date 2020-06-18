class StudiesController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :studies_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[edit update destroy manage manage_update show new_object_based_on_existing_one]

  # project_membership_required_appended is an alias to project_membership_required, but is necesary to include the actions
  # defined in the application controller
  before_action :project_membership_required_appended, only: [:new_object_based_on_existing_one]

  before_action :check_assays_are_not_already_associated_with_another_study, only: %i[create update]

  include Seek::Publishing::PublishingCommon
  include Seek::AnnotationCommon
  include Seek::IsaGraphExtensions

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
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def update
    @study = Study.find(params[:id])
    @study.attributes = study_params
    update_sharing_policies @study
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

  def show
    @study = Study.find(params[:id])

    respond_to do |format|
      format.html
      format.xml
      format.rdf { render template: 'rdf/show' }
      format.json {render json: @study, include: [params[:include]]}
    end
  end

  def create
    @study = Study.new(study_params)
    update_sharing_policies @study
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

  def investigation_selected_ajax
    if (investigation_id = params[:investigation_id]).present? && params[:investigation_id] != '0'
      investigation = Investigation.find(investigation_id)
      people = investigation.projects.collect(&:people).flatten
    end

    people ||= []

    render partial: 'studies/person_responsible_list', locals: { people: people }
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
    user_uuid = "#{User.current_user.attributes["uuid"]}"
    tempzip_path = params[:content_blobs][0][:data].tempfile.path
    data_files, studies = Study.unzip_batch(tempzip_path)
    study_filename = studies.first
    studies_file = ContentBlob.new
    studies_file.tmp_io_object = File.open("#{Rails.root}/tmp/#{user_uuid}_studies_upload/#{study_filename}")
    studies_file.original_filename = "#{study_filename}"
    studies_file.save!
    @studies = Study.extract_studies_from_file(studies_file)
    @study = @studies[0]
    @studies_datafiles = Study.extract_study_data_from_file(studies_file)
    render 'studies/batch_preview'
  end

  def batch_create
    # create method will be called for each study
    # e.g: Study.new(title: 'title', investigation: investigations(:metabolomics_investigation), policy: Factory(:private_policy))
    # study.policy = Policy.create(name: 'default policy', access_type: 1)
    # render plain: params[:studies].inspect
    user_uuid = "#{User.current_user.attributes["uuid"]}"
    metadata_types = CustomMetadataType.where(title: 'MIAPPE metadata', supported_type:'Study')
    studies_length = params[:studies][:title].length
    studies_uploaded = false
    data_file_uploaded = false

    studies_length.times do |index|
      metadata = generate_metadata(params[:studies], index)
      study_params = {
        title: params[:studies][:title][index],
        description: params[:studies][:description][index],
        investigation_id: params[:study][:investigation_id],
        person_responsible_id: params[:study][:person_responsible_id],
        custom_metadata: CustomMetadata.new(
          custom_metadata_type: metadata_types.first,
          data: metadata
      )
      }
      @study = Study.new(study_params)
      Study.check_study_is_valid(@study, metadata)
      if @study.valid? && @study.save! &&  @study.custom_metadata.valid?
        studies_uploaded = true if @study.save
      end


      data_file_names = params[:studies][:data_files][index].split(", ")
      data_file_names.length.times do |data_file_index|
        study_metadata_id = '"id":"' + params[:studies][:id][index] + '"'
        study_id = CustomMetadata.where("json_metadata LIKE ?", "%#{study_metadata_id}%").last.item_id
        assay_class_id = AssayClass.where(title: "Experimental assay").first.id
        data_file_description = params[:studies][:data_file_description][index].split(", ")
        assay_params = {
            title: 'Assay for ' + params[:studies][:id][index] + '-' + (data_file_index+1).to_s,
            description: data_file_description[data_file_index],
            study_id: study_id,
            assay_class_id: assay_class_id
        }

        data_file_name = "#{data_file_names[data_file_index]}.csv"
        data_file_url = "#{Rails.root}/tmp/#{user_uuid}_studies_upload/data/#{data_file_name}"
        data_file_content_blob = ContentBlob.new
        data_file_content_blob.tmp_io_object = File.open(data_file_url)
        data_file_content_blob.original_filename = "#{data_file_name}"

        #TODO Check and use the right license

        data_file_params = {
            title: data_file_names[data_file_index],
            description: data_file_description[data_file_index],
            license: "CC-BY-4.0",
            projects: Project.where(title: "Default Project"),
            content_blob: data_file_content_blob
        }

        assay_asset_params = {
            assay: Assay.new(assay_params),
            asset: DataFile.new(data_file_params)
        }
        @assay_asset = AssayAsset.new(assay_asset_params)

        if @assay_asset.valid? && @assay_asset.save!
          data_file_uploaded = true if @assay_asset.save
        end

      end


    end

    batch_uploaded = studies_uploaded && data_file_uploaded

    if batch_uploaded
      user_uuid = "#{User.current_user.attributes["uuid"]}"
      FileUtils.rm_r("#{Rails.root}/tmp/#{user_uuid}_studies_upload/")
      respond_to do |format|
        flash[:notice] = "The #{t('studies')} were successfully created.<br/>".html_safe
        format.html { redirect_to studies_path }
      end
    else
      respond_to do |format|
        format.html { render action: 'batch_preview', status: :unprocessable_entity }
      end
    end
  end

  def generate_metadata(studies_meta_data, index)
    metadata = {
        id: studies_meta_data[:id][index],
        study_start_date: studies_meta_data[:startDate][index],
        study_end_date: studies_meta_data[:endDate][index] || "",
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
        cultural_practices: studies_meta_data[:culturalPractices][index],
    }
    metadata
  end

  private
  def validate_person_responsible(p)
    if (!p[:person_responsible_id].nil?) && (!Person.exists?(p[:person_responsible_id]))
      render json: {error: 'Person responsible does not exist', status: :unprocessable_entity}, status: :unprocessable_entity
      return false
    end
    true
  end

  def study_params
    params.require(:study).permit(:title, :description, :experimentalists, :investigation_id, :person_responsible_id,
                                  :other_creators, { creator_ids: [] }, { scales: [] }, { publication_ids: [] },
                                  { custom_metadata_attributes: determine_custom_metadata_keys })
  end
end
