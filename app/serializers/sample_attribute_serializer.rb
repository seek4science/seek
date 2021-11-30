class SampleAttributeSerializer < BaseSerializer
  attributes :title, :sample_type, :sample_type_id,
             :sample_attribute_type, :sample_attribute_type_id,
             :unit, :unit_id, :pos, :description,
             :sample_controlled_vocab, :sample_controlled_vocab_id, :linked_sample_type_id,
             :required, :is_title, :template_column_index
end
