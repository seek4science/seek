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

  # Path for the cancel button on the ISA assay new/edit forms.
  # Editing: back to the assay itself. Creating: back to its parent (assay stream, or study for a new assay stream).
  def isa_assay_cancel_path(isa_assay)
    assay = isa_assay.assay
    target = if assay.persisted?
               assay
             else
               assay.assay_stream || assay.study
             end
    single_page_or_item_path(target, assays_path)
  end

  # Path for the cancel button on the ISA study new/edit forms.
  # Editing: back to the study itself. Creating: back to its investigation.
  def isa_study_cancel_path(isa_study)
    study = isa_study.study
    target = study.persisted? ? study : study.investigation
    single_page_or_item_path(target, studies_path)
  end

  # Path for the cancel button on the investigation new/edit forms.
  # Only ISA-JSON compliant investigations being edited get a path here; returns nil otherwise,
  # so form_submit_buttons falls back to its default cancel path.
  def investigation_cancel_path(investigation)
    return unless investigation.persisted? && investigation.is_isa_json_compliant_in_database

    single_page_or_item_path(investigation, investigation_path(investigation))
  end

  # SinglePagesController rejects requests unless both features are enabled.
  def single_page_available?
    Seek::Config.project_single_page_enabled && Seek::Config.isa_json_compliance_enabled
  end

  # The item in the single page view when available, otherwise the item's own page.
  # Uses fallback when the item is missing or not saved yet.
  def single_page_or_item_path(item, fallback)
    single_page_item_path(item) || (item&.persisted? ? polymorphic_path(item) : fallback)
  end

  # Single page path that selects the given investigation, study or assay in the tree.
  # Stays in the project the user came from (params[:single_page]) when the item belongs to it,
  # otherwise falls back to the item's first project.
  # Returns nil when the single page is unavailable, or the item or its project is missing.
  def single_page_item_path(item)
    return unless single_page_available?
    return if item.nil? || item.new_record?

    projects = item.projects
    project = projects.detect { |p| p.id.to_s == params[:single_page].to_s } if params[:single_page].present?
    project ||= projects.first
    return if project.nil?

    single_page_path(id: project, item_type: item.class.name.underscore, item_id: item.id)
  end

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
    return nil if value.blank?

    if attribute.sample_attribute_type.seek_cv_list?
      non_blank_values = value.compact_blank
      return nil if non_blank_values.blank?

      non_blank_values
    elsif attribute.sample_attribute_type.seek_sample_multi?
      non_blank_values = value.filter_map do |v|
        v unless v[:id].blank?
      end
      non_blank_values unless non_blank_values.blank?
    elsif is_registered_asset_type_attribute?(attribute)
      value unless value[:id].blank?
    else
      value
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
    sample_attribute.linked_sample_type.samples.authorized_for(:view).pluck(:id, :title).map do |id, title|
      { id: id, type: 'Sample', title: title }.to_json
    end
  end

  def get_values_for_sops(sample_attribute)
    is_assay_attribute = sample_attribute.sample_type.assays.any?
    if is_assay_attribute
      sops = sample_attribute.sample_type.assays.first.sops
    else
      sops = sample_attribute.sample_type.studies.first.sops
    end

    sops.authorized_for(:view).pluck(:id, :title).map { |id, title| { id: id, type: 'Sop', title: title }.to_json }

  end

  def get_values_for_datafiles
    DataFile.authorized_for(:view).pluck(:id, :title).map do |id, title|
      { id: id, type: 'DataFile', title: title }.to_json
    end
  end

  def get_values_for_strains
    Strain.authorized_for(:view).pluck(:id, :title).map do |id, title|
      { id: id, type: 'Strain', title: title }.to_json
    end
  end
end