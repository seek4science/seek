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
    { columns:, rows:, sample_types: sample_types.map { |s| { title: s.title, id: s.id } } }
  end

  private

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
    registered_sample_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE }
    registered_sample_multi_attributes = sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI }

    sample_type.samples.map do |s|
      sanitized_json_metadata = hide_unauthorized_inputs(JSON.parse(s.json_metadata), registered_sample_attributes, registered_sample_multi_attributes)
      if s.can_view?
        { 'selected' => '', 'id' => s.id, 'uuid' => s.uuid }.merge!(sanitized_json_metadata)
      else
        { 'selected' => '', 'id' => '#HIDDEN', 'uuid' => '#HIDDEN' }.merge!(sanitized_json_metadata&.transform_values { '#HIDDEN' })
      end
    end
  end

  def hide_unauthorized_inputs(json_metadata, registered_sample_attributes, registered_sample_multi_attributes)
    registered_sample_multi_attributes.map(&:title).each do |rsma|
      json_metadata = transform_registered_sample_multi(json_metadata, rsma)
    end
    registered_sample_attributes.map(&:title).each do |rma|
      json_metadata = transform_registered_sample_single(json_metadata, rma)
    end

    json_metadata
  end

  def transform_registered_sample_multi(json_metadata, input_key)
    unless input_key.nil?
        json_metadata[input_key] = json_metadata[input_key].map do |input|
        input_exists = Sample.where(id: input['id']).any?
        if !input_exists
          input
        elsif Sample.find(input['id']).can_view?
          input
        else
          { 'id' => input['id'], 'type' => input['type'], 'title' => '#HIDDEN' }
        end
      end
    end
    json_metadata
  end

  def transform_registered_sample_single(json_metadata, input_key)
    unless input_key.nil?
      input = json_metadata[input_key]
      input_exists = Sample.where(id: input['id']).any?
      if !input_exists
        json_metadata[input_key] = input
      elsif Sample.find(input['id']).can_view?
        json_metadata[input_key] = input
      else
        json_metadata[input_key] = { 'id' => input['id'], 'type' => input['type'], 'title' => '#HIDDEN' }
      end
    end
    json_metadata
  end

  def dt_cols(sample_type)
    attribs = sample_type.sample_attributes.map do |a|
      attribute = { title: a.title, name: sample_type.id.to_s, required: a.required, description: a.description,
                    is_title: a.is_title }
      attribute.merge!({ cv_id: a.sample_controlled_vocab_id }) unless a.sample_controlled_vocab_id.blank?
      is_seek_sample = a.sample_attribute_type.seek_sample?
      is_seek_multi_sample = a.sample_attribute_type.seek_sample_multi?
      is_cv_list = a.sample_attribute_type.seek_cv_list?
      cv_allows_free_text =  a.allow_cv_free_text
      attribute.merge!({ multi_link: true, linked_sample_type: a.linked_sample_type_id }) if is_seek_multi_sample
      attribute.merge!({ multi_link: false, linked_sample_type: a.linked_sample_type_id }) if is_seek_sample
      attribute.merge!({ is_cv_list: true, cv_allows_free_text:}) if is_cv_list
      attribute
    end
    (dt_default_cols(sample_type.id.to_s) + attribs).flatten
  end

  def dt_default_cols(name)
    [{ title: 'status', name:, status: true }, { title: 'id', name: }, { title: 'uuid', name: }]
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
    sample_types.flat_map do |s|
      s.sample_attributes.map do |a|
        attribute = { title: a.title, name: s.id.to_s, required: a.required, description: a.description,
                      is_title: a.is_title }
        is_seek_sample_multi = a.sample_attribute_type.seek_sample_multi?
        is_seek_sample = a.sample_attribute_type.seek_sample?
        is_cv_list = a.sample_attribute_type.seek_cv_list?
        attribute.merge!({ multi_link: true, linked_sample_type: a.linked_sample_type.id }) if is_seek_sample_multi
        attribute.merge!({ multi_link: false, linked_sample_type: a.linked_sample_type.id }) if is_seek_sample
        attribute.merge!({ is_cv_list: true }) if is_cv_list
        attribute
      end.unshift({ title: 'id' }, { title: 'uuid' })
    end
  end
end
