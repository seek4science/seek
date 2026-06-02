class StudyBatchUpload < ApplicationRecord


  def self.extract_study_data_from_file(studies_file)
    parsed_sheet = Seek::Templates::StudiesReader.new(studies_file)

    studies_data_files = {}
    columns = [2, 3, 4, 5]
    data_file_start_row_index = 4
    parsed_sheet.each_record(5, columns) do |index, data|
      if index > data_file_start_row_index

        study_id = data[0].value
        if !studies_data_files.key?(study_id)
          studies_data_files[study_id] = {data_file:[], data_file_description:[], data_file_version:[]}
        end

        data_file = data[1].value
        data_file_description = data[2].value
        data_file_version = data[3].value
        studies_data_files[study_id][:data_file] << data_file
        studies_data_files[study_id][:data_file_description] << data_file_description
        studies_data_files[study_id][:data_file_version] << data_file_version
      end
    end
    studies_data_files
  end

  def self.extract_studies_from_file(studies_file)
    studies = []
    parsed_sheet = Seek::Templates::StudiesReader.new(studies_file)
    metadata_type = ExtendedMetadataType.where(title: ExtendedMetadataType::MIAPPE_TITLE, supported_type: 'Study').last
    columns = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    study_start_row_index = 4
    parsed_sheet.each_record(3, columns) do |index, data|
      if index > study_start_row_index
        col = data.each_with_object({}) { |d, h| h[d.column] = d.value }
        studies << Study.new(
            title: col[3] || '',
            description: col[4] || '',
            extended_metadata: ExtendedMetadata.new(
                extended_metadata_type: metadata_type,
                data: generate_metadata(col)
            )
        )
      end
    end
    studies
  end

  def self.generate_metadata(col)
    {
      id: col[2] || '',
      study_start_date: validate_date(col[5]) ? col[5] : '',
      study_end_date: validate_date(col[6]) ? col[6] : '',
      contact_institution: col[7] || '',
      geographic_location_country: col[8] || '',
      experimental_site_name: col[9] || '',
      latitude: col[10] || '',
      longitude: col[11] || '',
      altitude: col[12] || '',
      description_of_the_experimental_design: col[13] || '',
      type_of_experimental_design: col[14] || '',
      observation_unit_level_hierarchy: col[15] || '',
      observation_unit_description: col[16] || '',
      description_of_growth_facility: col[17] || '',
      type_of_growth_facility: col[18] || '',
      cultural_practices: col[19] || ''
    }
  end


  def self.validate_date(date)
    return false if date.nil?

    format_ok = date.match(/\d{4}-\d{2}-\d{2}/)
    parseable = Date.strptime(date, '%Y-%m-%d') rescue false

    if format_ok && parseable
      return true
    else
      return false
    end
  end

  def self.unzip_batch(file_path, user = User.current_user)
    cleanup_stale_upload_directories
    dir = upload_directory(user)
    FileUtils.rm_r(dir) if dir.exist?
    dir.mkdir
    study_data = []
    studies = []
    Seek::Util.unzip(file_path, dir) do |entry|
      if entry.name.split('/').include?('data')
        study_data << dir.join(entry.name)
      else
        studies << dir.join(entry.name)
      end
    end
    [study_data, studies]
  end

  def self.get_existing_studies(studies)
    existing_studies = []
    studies.each do |study|
      study_metadata_id = study.extended_metadata.data[:id]
      find_metadata = ExtendedMetadata.where('json_metadata LIKE ?', "%\"id\":\"#{study_metadata_id}\"%")
      next if find_metadata.nil?

      find_metadata.each do |metadata|
        existing_study = Study.where(id: metadata.item_id).last
        old_study = {
            id: existing_study.id,
            metadata_id: metadata.id,
            study_miappe_id: study_metadata_id,
            description: existing_study.description
        }
        existing_studies << old_study
      end

    end
    existing_studies.to_json
  end

  def self.get_license_id(studies_file)
    default_license = 'CC-BY-SA-4.0'
    investigation_license_id = nil
    license_row_index = 7
    columns = [2]
    parsed_sheet = Seek::Templates::StudiesReader.new(studies_file)
    parsed_sheet.each_record(2, columns) do |index, data|
      investigation_license_id = data[0].value if index == license_row_index
    end
    normalized_input = investigation_license_id&.gsub(/[-_.\s]/, '')&.upcase
    Seek::License.combined.keys.find { |id| id.gsub(/[-_.\s]/, '').upcase == normalized_input } || default_license
  end

  def self.check_study_is_MIAPPE_compliant(study, metadata)
    mandatory_fields = %w[id title study_start_date contact_institution geographic_location_country experimental_site_name
                        description_of_the_experimental_design observation_unit_description description_of_growth_facility]
    missing_fields = []

    mandatory_fields.each do |mandatory_f|
      if study.attributes[mandatory_f].blank? && metadata[mandatory_f.to_sym].blank?
        missing_fields << mandatory_f
      end
    end

    missing_fields
  end

  def self.upload_directory(user = User.current_user)
    user_uuid = user ? user.uuid : 'user_uuid'
    Rails.root.join('tmp', "#{user_uuid}_studies_upload")
  end

  def self.data_directory(user = User.current_user)
    base = upload_directory(user)
    Pathname.glob(base.join('**', 'data')).find(&:directory?) || base.join('data')
  end

  def self.cleanup_stale_upload_directories(max_age: 24.hours)
    Dir.glob(Rails.root.join('tmp', '*_studies_upload')).each do |dir|
      FileUtils.rm_rf(dir) if File.mtime(dir) < max_age.ago
    end
  end

end
