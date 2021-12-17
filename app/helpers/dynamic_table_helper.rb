module DynamicTableHelper

  def dt_data(sample_type)
    rows = dt_rows(sample_type)
    columns = dt_cols(sample_type)
    return { columns: columns, rows: rows }
  end

  def dt_aggregated(study, include_all_assays = nil, assay = nil)
    if assay
      if assay.position == 0
        sample_types = [study.sample_types.second, assay.sample_type]
      else
        previous_assay = Assay.where(position: assay.position - 1).first
        sample_types = [previous_assay.sample_type, assay.sample_type]
      end
    else
      sample_types = study.sample_types
      sample_types.push(*study.assays.map {|a| a.sample_type }) if include_all_assays
    end
    columns = dt_cumulative_cols(sample_types)
    rows = dt_cumulative_rows(sample_types, columns.length)
    
    return { columns: columns, rows: rows }
  end

  private

  #---------- 

  def dt_rows(sample_type)
    sample_type.samples.map {|s| ["", s.id] + JSON(s.json_metadata).values}
  end

  def dt_cols(sample_type)
    attribs = sample_type.sample_attributes.map do |a|
      attribute = {title: a.title, name: sample_type.id.to_s}
      attribute.merge!({cv_id: a.sample_controlled_vocab_id}) if !a.sample_controlled_vocab_id.blank?
      condition = a.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
      attribute.merge!({multi_link: true, linked_sample_type: a.linked_sample_type.id }) if condition
      attribute
    end
    (dt_default_cols(sample_type.id.to_s) + attribs).flatten
  end

  def dt_default_cols(name)
    [{title:"status", name: name, status: true},{title:"id", name: name}]
  end

  #---------- Cumulative table

  def dt_cumulative_rows(sample_types, col_count)
    @arr, samples_graph, aggregated_rows = [], [], []
    sample_types.each do |s|
      row = {}
      s.samples.each { |sa| row[sa.id] = sa.linking_samples.map{ |l| l.id } }
      @arr << row
    end
    @arr[0].each { |x,arr| get_full_rows(x).each { |s| samples_graph << s } }

    samples_graph.each do |sample_id_set|
      full_row = []
      sample_id_set.each do |sample_id|
        full_row.push(*JSON(Sample.find(sample_id).json_metadata).values)
      end
      aggregated_rows << full_row.fill("", full_row.length..col_count-1)
    end
    aggregated_rows
  end

  def get_full_rows(x, row=[], i=0, rows=[])
    row << x
    links = @arr[i][x] if @arr[i]
    if (links && links.length > 0)
      links.each {|m| get_full_rows(m, row.clone, i+1, rows)}
    else 
      rows << row
    end
    rows
  end

  def dt_cumulative_cols(sample_types)
    return sample_types.flat_map do |s|
      s.sample_attributes.map do |a|
        attribute = { title: a.title, name: s.id.to_s }
        condition = a.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
        attribute.merge!({multi_link: true, linked_sample_type: a.linked_sample_type.id }) if condition
        attribute       
      end
    end
  end

end