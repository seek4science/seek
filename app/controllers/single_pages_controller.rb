require 'isatab_converter'

# Controller for the Single Page view
class SinglePagesController < ApplicationController
  include Seek::AssetsCommon
  include Seek::Sharing::SharingCommon
  include Seek::Publishing::PublishingCommon
  include Seek::Data::SpreadsheetExplorerRepresentation

  before_action :set_up_instance_variable
  before_action :project_single_page_enabled?
  before_action :check_user_logged_in,
                only: %i[batch_sharing_permission_preview batch_change_permission_for_selected_items]
  respond_to :html, :js

  def show
    @project = Project.find(params[:id])
    @folders = project_folders
    respond_to(&:html)
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

  def download_samples_excel
    sample_ids, sample_type_id, study_id, assay_id = Rails.cache.read(params[:uuid]).values_at(:sample_ids, :sample_type_id,
                                                                                               :study_id, :assay_id)

    @study = Study.find(study_id)
    @assay = Assay.find(assay_id) unless assay_id.nil?
    @project = @study.projects.first
    @samples = Sample.where(id: sample_ids)&.authorized_for(:view)&.sort_by(&:id)

    notice_message = "Contents of <b>#{@assay ? 'Assay [ID: ' + @assay.id.to_s + ', Title: ' + @assay.title : 'Study [ID: ' + @study.id.to_s + ', Title: ' + @study.title}]</b> downloaded:<br/><ul>"
    notice_message << "<li class='checkmark'><b>#{@samples.count < 1 ? 'No' : @samples.count} sample#{@samples.count != 1 ? 's' : ''}</b> visible to you #{@samples.count != 1 ? 'were' : 'was'} included</li>"
    raise 'Export aborted! Sample type not included in request!' if sample_type_id.nil?

    @sample_type = SampleType.find(sample_type_id)
    @template = Template.find(@sample_type.template_id)

    sample_attributes = @sample_type.sample_attributes.map do |sa|
      is_cv_list = sa.sample_attribute_type.base_type == Seek::Samples::BaseType::CV_LIST
      obj = if sa.sample_controlled_vocab_id.nil?
              { sa_cv_title: sa.title, sa_cv_id: nil }
            else
              { sa_cv_title: sa.title, sa_cv_id: sa.sample_controlled_vocab_id, allows_custom_input: sa.allow_cv_free_text }
            end
      obj.merge({ required: sa.required, is_cv_list: })
    end

    @sa_cv_terms = [{ name: 'id', has_cv: false, data: nil, allows_custom_input: nil, required: nil, is_cv_list: nil },
                    { name: 'uuid', has_cv: false, data: nil, allows_custom_input: nil, required: nil, is_cv_list: nil }]

    sample_attributes.map do |sa|
      if sa[:sa_cv_id].nil?
        @sa_cv_terms.push({ name: sa[:sa_cv_title], has_cv: false, data: nil,
                            allows_custom_input: nil, required: sa[:required], is_cv_list: nil })
      else
        sa_terms = SampleControlledVocabTerm.where(sample_controlled_vocab_id: sa[:sa_cv_id]).map(&:label)
        @sa_cv_terms.push({ name: sa[:sa_cv_title], has_cv: true, data: sa_terms,
                            allows_custom_input: sa[:allows_custom_input], required: sa[:required], is_cv_list: sa[:is_cv_list] })
      end
    end

    notice_message << '</ul>'
    flash[:notice] = notice_message.html_safe
    render xlsx: 'download_samples_excel', filename: 'samples_table.xlsx', disposition: 'inline'
  rescue StandardError => e
    flash[:error] = e.message
    respond_to do |format|
      format.html do
        redirect_to single_page_path(id: @project.id, item_type: @assay.nil? ? 'study' : 'assay',
                                     item_id: @assay.nil? ? @study.id : @assay.id)
      end
      format.json do
        render json: { parameters: { sample_ids:, sample_type_id:, study_id: }, errors: e }, status: :bad_request
      end
    end
  end

  def export_to_excel
    cache_uuid = UUID.new.generate
    id_label = "#{Seek::Config.instance_name} id"
    sample_ids = JSON.parse(params[:sample_data]).map { |sample| sample[id_label] }
    sample_type_id = JSON.parse(params[:sample_type_id])
    study_id = JSON.parse(params[:study_id])
    assay_id = JSON.parse(params[:assay_id])

    Rails.cache.write(cache_uuid, { "sample_ids": sample_ids.compact, "sample_type_id": sample_type_id, "study_id": study_id, "assay_id": assay_id },
                      expires_in: 1.minute)

    respond_to do |format|
      format.json { render json: { uuid: cache_uuid } }
    end
  end

  def upload_samples
    uploaded_file = params[:file]
    project_id = params[:project_id]
    @project = Project.find(project_id)

    # Check file type if is xls or xlsx
    case uploaded_file.content_type
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      spreadsheet_xml = spreadsheet_to_xml(uploaded_file.path, Seek::Config.jvm_memory_allocation)
      wb = parse_spreadsheet_xml(spreadsheet_xml)
      metadata_sheet = wb.sheet('Metadata')
      samples_sheet = wb.sheet('Samples')
    else
      raise "Please upload a valid spreadsheet file with extension '.xlsx'"
    end

    sample_type_id_ui = params[:sample_type_id].to_i

    unless valid_workbook?(wb)
      raise 'Invalid workbook! Cannot process this spreadsheet. Consider first exporting the table as a spreadsheet for the proper format.'
    end

    # Extract Samples metadata from spreadsheet
    study_id = metadata_sheet.cell(2, 2).value.to_i
    @study = Study.find(study_id)
    sample_type_id = metadata_sheet.cell(5, 2).value.to_i
    @sample_type = SampleType.find(sample_type_id)
    is_assay = @sample_type.assays.any?
    @assay = @sample_type.assays.first

    # Sample Type validation rules
    unless sample_type_id_ui == @sample_type&.id
      raise "Sample Type #{@sample_type&.id} from spreadsheet doesn't match Sample Type #{sample_type_id_ui} from the table. Please upload in the correct table."
    end
    unless @study.sample_types.include?(@sample_type) || is_assay
      raise "Sample Type '#{@sample_type.id}' doesn't belong to Study #{@study.id}. Sample Upload aborted."
    end
    unless (@assay&.sample_type == @sample_type) || !is_assay
      raise "Sample Type '#{@sample_type.id}' doesn't belong to Assay #{@assay.id}. Sample Upload aborted."
    end

    @multiple_input_fields = @sample_type.sample_attributes.map do |sa_attr|
      sa_attr.title if sa_attr.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
    end

    @registered_sample_fields = @sample_type.sample_attributes.map do |sa_attr|
      sa_attr.title if sa_attr.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE
    end

    @cv_list_fields = @sample_type.sample_attributes.map do |sa_attr|
      sa_attr.title if sa_attr.sample_attribute_type.base_type == Seek::Samples::BaseType::CV_LIST
    end

    sample_fields, samples_data = get_spreadsheet_data(samples_sheet)

    # Compare Excel header row to Sample Type Sample Attributes
    # Should raise an error if they don't match
    sample_type_attributes = [{ id: nil, title: 'id', is_cv: false, allows_custom_input: false, cv_terms: nil, required: true },
                              { id: nil, title: 'uuid', is_cv: false, allows_custom_input: false, cv_terms: nil, required: true }]
                             .concat(@sample_type.sample_attributes.includes(sample_controlled_vocab: [:sample_controlled_vocab_terms]).map do |sa|
                              if sa.controlled_vocab?
                                cv_terms = sa.sample_controlled_vocab.sample_controlled_vocab_terms.map(&:label)
                                { id: sa.id, title: sa.title, is_cv: sa.controlled_vocab?, allows_custom_input: sa.allow_cv_free_text?, cv_terms:, required: sa.required? }
                              else
                                { id: sa.id, title: sa.title, is_cv: sa.controlled_vocab?, allows_custom_input: sa.allow_cv_free_text?, cv_terms: nil, required: sa.required?}
                              end
                            end)

    has_unmapped_sample_attributes = sample_type_attributes.map { |sa| sample_fields.include?(sa[:title]) }.include?(false)
    if has_unmapped_sample_attributes
      raise "The Sample Attributes from the excel sheet don't match those of the Sample Type in the database. Sample upload was aborted!"
    end

    # Construct Samples objects from Excel data
    excel_samples = generate_excel_samples(samples_data, sample_fields, sample_type_attributes)

    existing_excel_samples = excel_samples.map { |sample| sample unless sample['id'].nil? }.compact
    new_excel_samples = excel_samples.map { |sample| sample if sample['id'].nil? }.compact

    # Retrieve all samples of the Sample Type, also the unauthorized ones
    @db_samples = sample_type_samples(@sample_type)
    # Retrieve the Sample Types samples wich are authorized for editing
    @authorized_db_samples = sample_type_samples(@sample_type, :edit)

    # Determine whether samples have been modified or not,
    # and checking whether the user is permitted to edit them
    @unauthorized_samples, @update_samples = separate_unauthorized_samples(existing_excel_samples, @db_samples,
                                                                           @authorized_db_samples)

    # Determine if the new samples are no duplicates of existing ones,
    # based on the attribute values
    @possible_duplicates, @new_samples = separate_possible_duplicates(new_excel_samples, @db_samples)

    upload_data = { study: @study,
                    assay: @assay,
                    sampleType: @sample_type,
                    excel_samples:,
                    existingExcelSamples: existing_excel_samples,
                    newExcelSamples: new_excel_samples,
                    updateSamples: @update_samples,
                    newSamples: @new_samples,
                    possibleDuplicates: @possible_duplicates,
                    dbSamples: @db_samples,
                    authorized_db_samples: @authorized_db_samples,
                    unauthorized_samples: @unauthorized_samples }

    respond_to do |format|
      format.json { render json: { uploadData: upload_data } }
      format.html { render 'single_pages/sample_upload_content', { layout: false } }
    end
  rescue StandardError => e
    flash[:error] = e.message
    respond_to do |format|
      format.html { redirect_to single_page_path(@project), status: :bad_request }
      format.json { render json: { error: e }, status: :bad_request }
    end
  end

  private

  def get_spreadsheet_data(samples_sheet)
    sample_fields = samples_sheet.row(1).actual_cells.map { |field| field&.value&.sub(' *', '') }.compact
    samples_data = (2..samples_sheet.actual_rows.size).map do |i|
      sample_cells = samples_sheet.row(i).cells
      next if sample_cells.all? { |cell| (cell&.value == '' || cell&.value.nil?) }

      sample_cells.map do |cell|
        cell&.value unless cell&.value == ''
      end.drop(1)
    end.compact

    [sample_fields, samples_data]
  end

  def generate_excel_samples(samples_data, sample_fields, sample_type_attributes)
    cv_sample_attributes = sample_type_attributes.select { |sa| sa[:is_cv] && !sa[:allows_custom_input] }
    samples_data.map do |excel_sample|
      obj = {}
      (0..sample_fields.size - 1).map do |i|
        current_sample_attribute = sample_type_attributes.detect { |sa| sa[:title] == sample_fields[i] }
        validate_cv_terms = cv_sample_attributes.map{ |cv_sa| cv_sa[:title] }.include?(sample_fields[i])
        validate_cv_terms &&= current_sample_attribute[:required] && !excel_sample[i].blank?
        attr_terms = validate_cv_terms ? cv_sample_attributes.detect { |sa| sa[:title] == sample_fields[i] }[:cv_terms] : []
        if @multiple_input_fields.include?(sample_fields[i])
          parsed_excel_input_samples = JSON.parse(excel_sample[i].gsub(/"=>/x, '":')).map do |subsample|
            # Uploader should at least have viewing permissions for the inputs he's using
            unless Sample.find(subsample['id'])&.authorized_for_view?
              raise "Unauthorized Sample was detected in spreadsheet: #{subsample.inspect}"
            end

            subsample
          end
          obj.merge!(sample_fields[i] => parsed_excel_input_samples)
        elsif @registered_sample_fields.include?(sample_fields[i])
          parsed_excel_registered_sample = JSON.parse(excel_sample[i].gsub(/"=>/x, '":'))
          unless Sample.find(parsed_excel_registered_sample['id'])&.authorized_for_view?
            raise "Unauthorized Sample was detected in spreadsheet: #{parsed_excel_registered_sample.inspect}"
          end
          obj.merge!(sample_fields[i] => parsed_excel_registered_sample)
        elsif @cv_list_fields.include?(sample_fields[i])
          parsed_cv_terms = JSON.parse(excel_sample[i])
          # CV validation for CV_LIST attributes
          parsed_cv_terms.map do |term|
            if !attr_terms.include?(term) && validate_cv_terms
              raise "Invalid Controlled vocabulary term detected '#{term}' in sample ID #{excel_sample[0]}: { #{sample_fields[i]}: #{parsed_cv_terms.inspect} }"
            end
          end
          obj.merge!(sample_fields[i] => parsed_cv_terms)
        elsif sample_fields[i] == 'id'
          if excel_sample[i].blank?
            obj.merge!(sample_fields[i] => nil)
          else
            obj.merge!(sample_fields[i] => excel_sample[i]&.to_i)
          end
        else
          if validate_cv_terms
            unless attr_terms.include?(excel_sample[i])
              raise "Invalid Controlled vocabulary term detected '#{excel_sample[i]}' in sample ID #{excel_sample[0]}: { #{sample_fields[i]}: #{excel_sample[i]} }"
            end
          end
          obj.merge!(sample_fields[i] => excel_sample[i])
        end
      end
      obj
    end
  end

  def sample_type_samples(sample_type, authorization_method = nil)
    if authorization_method
      sample_type.samples&.authorized_for(authorization_method)&.map do |sample|
        attributes = JSON.parse(sample[:json_metadata])
        { 'id' => sample.id,
          'uuid' => sample.uuid }.merge(attributes)
      end
    else
      sample_type.samples&.map do |sample|
        attributes = JSON.parse(sample[:json_metadata])
        { 'id' => sample.id,
          'uuid' => sample.uuid }.merge(attributes)
      end
    end
  end

  def separate_unauthorized_samples(existing_excel_samples, db_samples, authorized_db_samples)
    update_samples = []
    unauthorized_samples = []
    existing_excel_samples.map do |ees|
      db_sample = db_samples.select { |s| s['id'] == ees['id'] }.first

      # An exception is raised if the ID of an existing Sample cannot be found in the DB
      raise "Sample with id '#{ees['id']}' does not exist in the database. Sample upload was aborted!" if db_sample.nil?

      is_authorized_for_update = authorized_db_samples.select { |s| s['id'] == ees['id'] }.any?

      is_changed = false

      db_sample.map do |k, v|
        unless ees[k] == v || %w[id uuid].include?(k)
          is_changed = true
          break
        end
      end

      if is_changed
        if is_authorized_for_update
          update_samples.append(ees)
        else
          unauthorized_samples.append(ees)
        end
      end
    end
    [unauthorized_samples, update_samples]
  end

  def separate_possible_duplicates(new_excel_samples, db_samples)
    possible_duplicates = []
    new_samples = []
    new_excel_samples.map do |nes|
      is_duplicate = true

      db_samples.map do |dbs|
        dbs.map do |k, v|
          unless %w[id uuid].include?(k)
            is_duplicate = (nes[k] == v)
            break unless is_duplicate
          end
        end

        if is_duplicate
          possible_duplicates.append(nes.merge({ 'duplicate' => dbs }))
          break
        end
      end

      if db_samples.none?
        new_samples.append(nes)
      else
        new_samples.append(nes) unless is_duplicate
      end
    end
    [possible_duplicates, new_samples]
  end

  def valid_workbook?(workbook)
    !((workbook.sheet_names.map do |sheet|
         %w[Metadata Samples cv_ontology].include? sheet
       end.include? false) && (workbook.sheets.size != 3))
  end

  def set_up_instance_variable
    @single_page = true
  end

  def check_user_logged_in
    return if current_user

    render json: { status: :unprocessable_entity, error: 'You must be logged in to access batch sharing permission.' }
  end
end
