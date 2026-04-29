module SinglePagesHelper
  ## Function to get a fixed size matrix
  def transposed_filled_arrays(arrays)
    raise 'Input is no array' unless arrays.is_a?(Array)

    size = 0
    arrays.map { |array| size = array.size if array.size > size }

    filled_arrays = []
    arrays.map { |array| filled_arrays.push(Array.new(size) { |i| array[i] }) }

    filled_arrays.transpose
  end

  ATTRIBUTES_WITH_DATA_VALIDATION = [
    Seek::Samples::BaseType::CV,
    Seek::Samples::BaseType::SEEK_SAMPLE,
    Seek::Samples::BaseType::SEEK_DATA_FILE,
    Seek::Samples::BaseType::SEEK_STRAIN,
    Seek::Samples::BaseType::SEEK_SOP,
  ]

  REGISTERED_ASSET_TYPE_ATTRIBUTES = [
    Seek::Samples::BaseType::SEEK_SAMPLE,
    Seek::Samples::BaseType::SEEK_DATA_FILE,
    Seek::Samples::BaseType::SEEK_STRAIN,
    Seek::Samples::BaseType::SEEK_SOP,
  ]

  def requires_data_validation?(sample_attribute)
    ATTRIBUTES_WITH_DATA_VALIDATION.include?(sample_attribute.sample_attribute_type.base_type)
  end

  def is_registered_asset_type_attribute?(sample_attribute)
    REGISTERED_ASSET_TYPE_ATTRIBUTES.include?(sample_attribute.sample_attribute_type.base_type)
  end

  def get_sample_metadata_for_spreadsheet(sample, sample_attributes)
    sample_metadata = {}
    sample_attributes.each do |attribute|
      attribute_value = sample.get_attribute_value(attribute)
      sample_metadata[attribute.accessor_name] = format_attribute_value_for_spreadsheet(attribute_value, attribute)
    end
    sample_metadata
  end

  # Filters out all 'blank' type of values like
  # "", [], [nil], [""], {id => nil...}, {id => ""...}, [{id => ""...}], [{id => nil...}]
  # and returns `nil` if no meaningful value is found for that attribute
  def format_attribute_value_for_spreadsheet(value, attribute)
    if attribute.sample_attribute_type.seek_cv_list?
      unless value.blank?
        non_blank_values = value.compact_blank
        non_blank_values unless non_blank_values.blank?
      end
    elsif attribute.sample_attribute_type.seek_sample_multi?
      unless value.blank?
        non_blank_values = value.map do |v|
          v unless v[:id].blank?
        end.compact
        non_blank_values unless non_blank_values.blank?
      end
    elsif is_registered_asset_type_attribute?(attribute)
      value unless value[:id].blank?
    else
      value unless value.blank?
    end
  end

  def get_values_for_attribute(attribute)
    type = attribute.sample_attribute_type
    if type.controlled_vocab?
      get_values_for_cv(attribute)
    elsif type.seek_sample? || type.seek_sample_multi?
      get_values_for_registered_samples(attribute)
    elsif type.seek_data_file?
      get_values_for_datafiles
    elsif type.seek_strain?
      get_values_for_strains
    elsif type.seek_sop?
      get_values_for_sops(attribute)
    else
      []
    end
  end

  def get_values_for_cv(sample_attribute)
    sample_attribute.sample_controlled_vocab.labels
  end

  def get_values_for_registered_samples(sample_attribute)
    sample_attribute.linked_sample_type.samples.authorized_for(:view).map do |sample|
      { id: sample.id, type: 'Sample', title: sample.title }.to_json
    end
  end

  def get_values_for_sops(sample_attribute)
    is_assay_attribute = sample_attribute.sample_type.assays.any?
    if is_assay_attribute
      sops = sample_attribute.sample_type.assays.first.sops
    else
      sops = sample_attribute.sample_type.studies.first.sops
    end

    sops.authorized_for(:view).map { |sop| { id: sop.id, type: 'Sop', title: sop.title }.to_json }
  end

  def get_values_for_datafiles
    data_files = DataFile.authorized_for(:view)
    data_files.map { |data_file| { id: data_file.id, type: 'DataFile', title: data_file.title }.to_json }
  end

  def get_values_for_strains
    strains = Strain.authorized_for(:view)
    strains.map { |strain| { id: strain.id, type: 'Strain', title: strain.title }.to_json }
  end
end