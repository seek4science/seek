require 'isatab_converter'
require 'roo'
require 'roo-xls'

class SinglePagesController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Sharing::SharingCommon

  before_action :set_up_instance_variable
  before_action :project_single_page_enabled?
  before_action :find_authorized_investigation, only: :export_isa
  before_action :check_user_logged_in,
                only: %i[batch_sharing_permission_preview batch_change_permission_for_selected_items]
  respond_to :html, :js

  def show
    @project = Project.find(params[:id])
    @folders = project_folders

    respond_to do |format|
      format.html
    end
  end

  def index; end

  def project_folders
    return unless Seek::Config.project_single_page_folders_enabled

    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

  def dynamic_table_data
    data = []
    if params[:sample_type_id]
      sample_type = SampleType.find(params[:sample_type_id]) if params[:sample_type_id]
      data = helpers.dt_data(sample_type)[:rows]
    elsif params[:study_id]
      study = Study.find(params[:study_id]) if params[:study_id]
      assay = Assay.find(params[:assay_id]) if params[:assay_id]
      data = helpers.dt_aggregated(study, assay)[:rows]
    end
    data = data.map { |row| row.unshift('') } if params[:rows_pad]
    render json: { data: data }
  rescue Exception => e
    render json: { status: :unprocessable_entity, error: e.message }
  end

  def export_isa
    raise 'The investigation cannot be found!' if @inv.blank?

    isa = IsaExporter::Exporter.new(@inv).export
    send_data isa, filename: 'isa.json', type: 'application/json', deposition: 'attachment'
  rescue Exception => e
    respond_to do |format|
      flash[:error] = e.message
      format.html { redirect_to single_page_path(Project.find(params[:id])) }
    end
  end

  def upload_samples
    wb = Roo::Excelx.new(params[:file].path)
    puts params
    # Extract Samples metadata
    study_id = wb.cell(2, 2, sheet = 'Metadata').to_i
    sample_type_id = wb.cell(5, 2, sheet = 'Metadata').to_i
    template_id = wb.cell(8, 2, sheet = 'Metadata').to_i

    @study = Study.find(study_id)
    @sample_type = SampleType.find(sample_type_id)
    @template = Template.find(template_id)
    @project = @study.projects.first # In Single Page a study can only belong to one project

    sample_fields = wb.row(1, sheet = 'Samples').map { |field| field.sub(' *', '') }
    samples_data = (2..wb.last_row(sheet = 'Samples')).map { |i| wb.row(i, sheet = 'Samples') }

    @excel_samples = samples_data.map do |excel_sample|
      obj = {}
      (0..sample_fields.size - 1).map do |i|
        obj.merge!(sample_fields[i] => excel_sample[i])
      end
      obj
    end

    @existing_excel_samples = @excel_samples.map { |sample| sample unless sample['id'].nil? }.compact
    @new_excel_samples = @excel_samples.map { |sample| sample if sample['id'].nil? }.compact

    @db_samples = @sample_type.samples&.authorized_for(:edit)&.map do |sample|
      attributes = JSON.parse(sample[:json_metadata])
      { 'id' => sample.id,
        'uuid' => sample.uuid }.merge(attributes)
    end

    # Determine whether samples have been modified or not
    @update_samples = @existing_excel_samples.map do |ees|
      db_sample = @db_samples.select { |s| s['id'] == ees['id'] }.first
      # An exception is raised if the ID of an existing Sample cannot be found in the DB
      raise "Sample with id '#{ees['id']}' does not exist in the database. Sample upload was aborted!" if db_sample.nil?
      is_changed = false

      db_sample.map do |k, v|
        unless ees[k] == v
          is_changed = true
          break
        end
      end

      ees if is_changed
    end
    @update_samples.compact!

    # Determine if the new samples are no duplicates of existing ones,
    # based on the attribute values
    @possible_duplicates = []
    @new_samples = []
    @new_excel_samples.map do |nes|
      is_duplicate = true

      @db_samples.map do |dbs|
        dbs.map do |k, v|
          unless %w[id uuid].include?(k)
            is_duplicate = (nes[k] == v)
            break unless is_duplicate
          end
        end
        if is_duplicate
          @possible_duplicates.append(nes.merge({ 'duplicate' => dbs }))
          break
        end
      end
      @new_samples.append(nes) unless is_duplicate
    end

    upload_data = { study: @study,
                    sampleType: @sample_type,
                    template: @template,
                    excelSamples: @excel_samples,
                    existingExcelSamples: @existing_excel_samples,
                    newExcelSamples: @new_excel_samples,
                    updateSamples: @update_samples,
                    newSamples: @new_samples,
                    possibleDuplicates: @possible_duplicates,
                    dbSamples: @db_samples }


    respond_to do |format|
      format.json { render json: { uploadData: upload_data } }
      format.html { render 'single_pages/sample_upload_content', { layout: false } }
    end
  end

  private

  def set_up_instance_variable
    @single_page = true
  end

  def find_authorized_investigation
    investigation = Investigation.find(params[:investigation_id])
    @inv = investigation if investigation.can_edit?
  end

  def check_user_logged_in
    unless current_user
      render json: { status: :unprocessable_entity, error: 'You must be logged in to access batch sharing permission.' }
    end
  end

end
