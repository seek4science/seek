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

  def requires_data_validation?(sample_attribute)
    ATTRIBUTES_WITH_DATA_VALIDATION.include?(sample_attribute.sample_attribute_type.base_type)
  end

  def get_values_for_attribute(attribute)
    case attribute.sample_attribute_type
    when controlled_vocab?
      get_values_for_cv(attribute)
    when seek_sample? || seek_sample_multi?
      get_values_for_registered_samples(attribute)
    when seek_data_file?
      get_values_for_datafiles(attribute)
    when seek_strain?
      get_values_for_strains(attribute)
    when seek_sop?
      get_values_for_sops(attribute)
    else
      []
    end
  end
  def get_values_for_cv(sample_attribute)
    sample_attribute.sample_controlled_vocab.labels
  end

  def get_values_for_registered_samples(sample_attribute)
    sample_attribute.linked_sample_type.samples.map do |sample|
      { id: sample.id, type: 'Sample', title: sample.title }
    end
  end

  def get_values_for_sops(sample_attribute)
    is_assay_attribute = sample_attribute.sample_type.assays.any?
    if is_assay_attribute
      sops = sample_attribute.sample_type.assays.first.sops
    else
      sops = sample_attribute.sample_type.studies.first.sops
    end

    sops.map { |sop| { id: sop.id, type: 'Sop', title: sop.title } }
  end

  def get_values_for_datafiles(sample_attribute)
    data_files = sample_attribute.sample_type.projects.first.data_files
    data_files.map { |data_file| { id: data_file.id, type: 'DataFile', title: data_file.title } }
  end

  def get_values_for_strains(sample_attribute)
    strains = sample_attribute.sample_type.projects.first.strains
    strains.map { |strain| { id: strain.id, type: 'Strain', title: strain.title } }
  end
end