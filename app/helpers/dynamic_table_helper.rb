module DynamicTableHelper
  def dt_data(sample_type)
    rows = dt_rows(sample_type)
    columns = dt_cols(sample_type)
    { columns: columns, rows: rows }
  end

  def dt_aggregated(study, include_all_assays = nil, assay = nil)
    if assay
			sample_types = link_sequence(assay.sample_type).reverse.drop(2)
    else
      sample_types = study.sample_types.map(&:clone)
      sample_types.push(*study.assays.map(&:sample_type)) if include_all_assays
    end
    columns = dt_cumulative_cols(sample_types)
    rows = dt_cumulative_rows(sample_types, columns.length)
    { columns: columns, rows: rows }
  end

  private

	def link_sequence(sample_type)
		sequence = [sample_type]
		while link = sample_type.sample_attributes.detect(&:seek_sample_multi?)&.linked_sample_type
			sequence << link
			sample_type = link
		end
		sequence
	end


  def dt_rows(sample_type)
    sample_type.samples.map do |s|
			['', s.id] +
			if s.can_view?
			  JSON(s.json_metadata).values
			else
			  Array.new(JSON(s.json_metadata).length, "#HIDDEN")
			end
		end
  end

  def dt_cols(sample_type)
    attribs = sample_type.sample_attributes.map do |a|
      attribute = { title: a.title, name: sample_type.id.to_s, required: a.required, description: a.description }
      attribute.merge!({ cv_id: a.sample_controlled_vocab_id }) unless a.sample_controlled_vocab_id.blank?
      condition = a.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
      attribute.merge!({ multi_link: true, linked_sample_type: a.linked_sample_type.id }) if condition
      attribute
    end
    (dt_default_cols(sample_type.id.to_s) + attribs).flatten
  end

  def dt_default_cols(name)
    [{ title: 'status', name: name, status: true }, { title: 'id', name: name }]
  end

  def dt_cumulative_rows(sample_types, col_count)
    @arr, samples_graph, aggregated_rows = [], [], []
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
					full_row.push(*JSON(sample.json_metadata).values.unshift(sample.id))
				else
					full_row.push(*Array.new(JSON(sample.json_metadata).length, "#HIDDEN").unshift(sample.id))
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
        attribute = { title: a.title, name: s.id.to_s, required: a.required, description: a.description }
        condition = a.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
        attribute.merge!({ multi_link: true, linked_sample_type: a.linked_sample_type.id }) if condition
        attribute
      end.unshift({ title: 'id' })
    end
  end
end
