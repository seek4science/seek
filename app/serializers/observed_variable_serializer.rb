class ObservedVariableSerializer < ActiveModel::Serializer
  attributes :id, :observed_variable_set_id, :variable_id, :variable_name, :variable_an, :trait, :trait_an, :trait_entity, :trait_entity_an, :trait_attribute, :trait_attribute_an, :method, :method_an, :method_description, :method_reference, :scale, :scale_an, :timescale
end
