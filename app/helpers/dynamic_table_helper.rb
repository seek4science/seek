module DynamicTableHelper
  def dt_data(sample_type)
    columns = dt_cols(sample_type)
    rows = dt_rows(sample_type)
    row_values = get_rows_for_columns(rows, columns)
    { columns:, rows: row_values }
  end

  # Gets the row values from the JSON metadata in the order that the columns are.
  # Makes switching attribute positions possible without scrambling the JSON metadata
  def get_rows_for_columns(rows, columns)
    rows.map do |row|
      columns.map do |col|
        row[col[:title]]
      end
    end
  end

  def dt_aggregated(study, assay = nil)
    sample_types =
      if assay
        link_sequence(assay.sample_type).reverse.drop(2) # Remove the two Study sample types, so only the assays remain
      else
        study.sample_types.map(&:clone)
      end
    columns = dt_cumulative_cols(sample_types)
    rows = dt_cumulative_rows(sample_types, columns.length)
    { columns:, rows:, sample_types: sample_types.map { |s| { title: s.title, id: s.id, assay_title: s.assays.first&.title } } }
  end

  private

  ALLOWED_MODELS = %w[Sop Sample DataFile Strain]

  # Links all sample_types in a sequence of sample_types
  def link_sequence(sample_type)
    sequence = [sample_type]
    while link = sample_type.previous_linked_sample_type
      sequence << link
      sample_type = link
    end
    sequence
  end

  def dt_rows(sample_type)
    registered_sample_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.seek_sample? }
    registered_sample_multi_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.seek_sample_multi? }
    registered_sop_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.seek_sop? }
    registered_data_file_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.seek_data_file? }
    strain_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.seek_strain? }

    sample_type.samples.map do |s|
      sanitized_json_metadata = sanitize_metadata(JSON.parse(s.json_metadata),
                                                  registered_sample_attributes,
                                                  registered_sample_multi_attributes,
                                                  registered_sop_attributes,
                                                  registered_data_file_attributes,
                                                  strain_attributes)
      if s.can_view?
        { 'selected' => '', 'id' => s.id, 'uuid' => s.uuid }.merge!(sanitized_json_metadata)
      else
        { 'selected' => '', 'id' => '#HIDDEN', 'uuid' => '#HIDDEN' }.merge!(sanitized_json_metadata.transform_values { '#HIDDEN' })
      end
    end
  end

  def sanitize_metadata(json_metadata,
                        registered_sample_attributes,
                        registered_sample_multi_attributes,
                        registered_sop_attributes,
                        registered_data_file_attributes,
                        strain_attributes)
    registered_sample_multi_attributes.map(&:title).each do |rsma|
      json_metadata = transform_non_text_attributes_multi(json_metadata, rsma)
    end
    registered_sample_attributes.map(&:title).each do |rma|
      json_metadata = transform_non_text_attributes_single(json_metadata, rma)
    end
    registered_sop_attributes.map(&:title).each do |rsa|
      json_metadata = transform_non_text_attributes_single(json_metadata, rsa)
    end

    registered_data_file_attributes.map(&:title).each do |rda|
      json_metadata = transform_non_text_attributes_single(json_metadata, rda)
    end

    strain_attributes.map(&:title).each do |strain_attr|
      json_metadata = transform_non_text_attributes_single(json_metadata, strain_attr)
    end

    json_metadata
  end

  def transform_non_text_attributes_multi(json_metadata, multi_non_text_attribute_title)
    unless multi_non_text_attribute_title.nil?
      original_metadata = json_metadata[multi_non_text_attribute_title]
      json_metadata[multi_non_text_attribute_title] = original_metadata.map do |obj|
        hide_unauthorized_metadata(obj)
      end
    end
    json_metadata
  end

  def transform_non_text_attributes_single(json_metadata, non_text_attribute_title)
    unless non_text_attribute_title.nil?
      json_metadata[non_text_attribute_title] = hide_unauthorized_metadata(json_metadata[non_text_attribute_title])
    end
    json_metadata
  end

  def hide_unauthorized_metadata(obj)
    model = obj['type']
    raise "Not allowed to look up #{model}!" unless ALLOWED_MODELS.include?(model)

    item = model.constantize.find_by(id: obj['id']) if obj['id'].present?
    item_exists = !item.nil?
    if item_exists && !item&.can_view?
      { 'id' => obj['id'], 'type' => obj['type'], 'title' => '#HIDDEN' }
    else
      obj
    end
  end

  def dt_cols(sample_type)
    attribs = sample_type.sample_attributes.map do |a|
      unit = a.unit.slice(:id, :title, :symbol, :comment) if a.unit
      attribute = { title: a.title, name: sample_type.id.to_s, required: a.required, description: a.description,
                    is_title: a.is_title, attribute_type: a.sample_attribute_type&.base_type, unit: unit || {} }

      if a.sample_attribute_type&.controlled_vocab?
        cv_allows_free_text = a.allow_cv_free_text
        attribute.merge!({ cv_allows_free_text: cv_allows_free_text, cv_id: a.sample_controlled_vocab_id })
      end

      if a.sample_attribute_type&.seek_sample_multi? || a.sample_attribute_type&.seek_sample?
        attribute.merge!(linked_sample_type: a.linked_sample_type_id)
      end

      if a.input_attribute?
        attribute.merge!(is_input: true)
      end

      attribute
    end
    (dt_default_cols(sample_type.id.to_s) + attribs).flatten
  end

  def dt_default_cols(name)
    [{ title: 'status', name:, status: true, unit: {} }, { title: 'id', name: , unit: {}}, { title: 'uuid', name: , unit: {} }]
  end

  def dt_cumulative_rows(sample_types, col_count)
    @arr = []
    samples_graph = []
    aggregated_rows = []
    sample_types.each do |s|
      row = {}
      s.samples.each { |sa| row[sa.id] = sa.linking_samples.map(&:id) }
      @arr << row
    end
    @arr[0].each { |x, _| get_full_rows(x, sample_types.length - 1).each { |s| samples_graph << s } }
    samples_graph.each do |sample_id_set|
      full_row = []
      sample_id_set.each do |sample_id|
        sample = Sample.find(sample_id)
        if sample.can_view?
          full_row.push(*JSON(sample.json_metadata).values.unshift(sample.id, sample.uuid))
        else
          full_row.push(*Array.new(JSON(sample.json_metadata).length, '#HIDDEN').unshift('#HIDDEN', '#HIDDEN'))
        end
      end
      aggregated_rows << full_row.fill('', full_row.length..col_count - 1)
    end
    aggregated_rows
  end

  def get_full_rows(x, depth, row = [], i = 0, rows = [])
    row << x
    links = @arr[i][x] if @arr[i]
    if links&.length&.positive? && i < depth
      links.each { |m| get_full_rows(m, depth, row.clone, i + 1, rows) }
    else
      rows << row
    end
    rows
  end

  def dt_cumulative_cols(sample_types)
    sample_types.flat_map.with_index do |s, i|
      s.sample_attributes.map do |a|
        unit = a.unit.slice(:id, :title, :symbol, :comment) if a.unit
        attribute = { title: a.title, name: s.id.to_s, required: a.required, description: a.description,
                      is_title: a.is_title, attribute_type: a.sample_attribute_type&.base_type, unit: unit || {} }
        is_seek_sample_multi = a.sample_attribute_type.seek_sample_multi?
        is_seek_sample = a.sample_attribute_type.seek_sample?
        is_cv_list = a.sample_attribute_type.seek_cv_list?
        is_input = a.input_attribute?
        attribute.merge!(linked_sample_type: a.linked_sample_type.id) if is_seek_sample_multi || is_seek_sample
        # The first input has to show up in the experiment view,
        # that's why when i=0, the `is_first_input` flag is set to true.
        attribute.merge!({ is_input: true, is_first_input: i == 0 }) if is_input
        attribute.merge!(is_cv_list: true) if is_cv_list
        attribute
      end.unshift({ title: 'id', is_id_field: true }, { title: 'uuid', is_id_field: true })
    end
  end
end
