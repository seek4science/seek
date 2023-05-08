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
    render json: { data: }
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
    puts wb.cell(2, 2, sheet = 'Metadata').to_i
    puts wb.cell(5, 2, sheet = 'Metadata').to_i
    puts wb.cell(8, 2, sheet = 'Metadata').to_i

    @study = Study.find(wb.cell(2, 2, sheet = 'Metadata').to_i)
    @sample_type = SampleType.find(wb.cell(5, 2, sheet = 'Metadata').to_i)
    @template = Template.find(wb.cell(8, 2, sheet = 'Metadata').to_i)

    sample_fields = wb.row(1, sheet = 'Samples')
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

    @db_samples = @existing_excel_samples.map { |sample| JSON.parse(Sample.find(sample['id'])[:json_metadata]) }

    [@study, @sample_type, @template, @excel_samples, @existing_excel_samples, @new_excel_samples, @db_samples].each do |var|
      puts '#' * 100
      puts var.inspect
    end
    puts '#' * 100

    # respond_to do |format|
    #   format.html { redirect_to single_page_path(@study.projects.first) }
    # end
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
