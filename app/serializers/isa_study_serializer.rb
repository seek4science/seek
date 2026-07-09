class ISAStudySerializer < SimpleBaseSerializer
  def id
    object.study&.id&.to_s
  end

  def type
    'isa_studies'
  end

  attribute :study
  attribute :source_sample_type
  attribute :sample_collection_sample_type

  def study
    return nil unless object.study

    {
      id: object.study.id.to_s,
      title: object.study.title,
      description: object.study.description,
      experimentalists: object.study.experimentalists,
      other_creators: object.study.other_creators,
      position: object.study.position
    }
  end

  def source_sample_type
    serialize_isa_sample_type(object.source)
  end

  def sample_collection_sample_type
    serialize_isa_sample_type(object.sample_collection)
  end

  def _meta
    meta = super
    study_obj = object.study
    meta[:uuid] = study_obj&.uuid if study_obj.respond_to?('uuid')
    meta[:created] = study_obj&.created_at if study_obj.respond_to?('created_at')
    meta[:modified] = study_obj&.updated_at if study_obj.respond_to?('updated_at')
    meta
  end

  private

  def serialize_isa_sample_type(sample_type)
    return nil unless sample_type

    {
      id: sample_type.id.to_s,
      title: sample_type.title,
      description: sample_type.description,
      template_id: sample_type.template_id,
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
        template_attribute_id: attr.template_attribute_id,
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
