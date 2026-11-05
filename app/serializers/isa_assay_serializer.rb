class ISAAssaySerializer < SimpleBaseSerializer
  def id
    object.assay&.id&.to_s
  end

  def type
    'isa_assays'
  end

  attribute :assay
  attribute :sample_type
  attribute :input_sample_type_id

  def assay
    return nil unless object.assay

    {
      id: object.assay.id.to_s,
      title: object.assay.title,
      description: object.assay.description,
      other_creators: object.assay.other_creators,
      position: object.assay.position,
      study_id: object.assay.study_id&.to_s,
      assay_class: {
        title: object.assay.assay_class&.title,
        key: object.assay.assay_class&.key
      },
      assay_type: {
        label: object.assay.assay_type_label,
        uri: object.assay.assay_type_uri
      },
      technology_type: {
        label: object.assay.technology_type_label,
        uri: object.assay.technology_type_uri
      }
    }
  end

  def sample_type
    serialize_isa_sample_type(object.sample_type)
  end

  def input_sample_type_id
    object.input_sample_type_id&.to_s
  end

  def meta_item
    object.assay
  end

  private

  def serialize_isa_sample_type(sample_type)
    return nil unless sample_type

    {
      id: sample_type.id.to_s,
      title: sample_type.title,
      description: sample_type.description,
      template_id: sample_type.template_id&.to_s,
      sample_attributes: serialize_isa_sample_attributes(sample_type),
      samples: serialize_viewable_samples(sample_type)
    }
  end

  def serialize_viewable_samples(sample_type)
    sample_type.samples.authorized_for('view').map do |sample|
      { id: sample.id.to_s, title: sample.title, data: sample.data.to_hash }
    end
  end

  def serialize_isa_sample_attributes(sample_type)
    sample_type.sample_attributes.collect do |attr|
      {
        id: attr.id.to_s,
        title: attr.title,
        pos: attr.pos,
        required: attr.required,
        is_title: attr.is_title,
        template_attribute_id: attr.template_attribute_id&.to_s,
        isa_tag_id: attr.isa_tag_id&.to_s,
        sample_attribute_type: {
          id: attr.sample_attribute_type_id&.to_s,
          title: attr.sample_attribute_type&.title
        },
        linked_sample_type_id: attr.linked_sample_type_id&.to_s,
        unit: attr.unit&.symbol,
        description: attr.description,
        pid: attr.pid
      }
    end
  end
end
