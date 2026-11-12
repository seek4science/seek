module Seek
  module RoCrate
    class ISACrateBuilder
      # Extended metadata of an investigation, study or assay as PropertyValue entities.
      module ExtendedMetadata
        # The resource whose metadata is being written and the id prefix of its values ("assay-3").
        Owner = Struct.new(:resource, :prefix)

        private

        # Every filled extended metadata attribute of a resource as references to PropertyValue
        # entities with ids like "#assay-3-facility". An attribute that holds a nested record is
        # flattened, its values named "parent.child".
        def extended_metadata_references(crate, resource, type_name)
          record = resource.extended_metadata
          return [] if record.blank? || record.extended_metadata_type.nil?

          owner = Owner.new(resource, "#{type_name.downcase}-#{resource.id}")
          property_values(crate, owner, record.extended_metadata_type) do |attribute|
            record.get_attribute_value(attribute)
          end
        end

        def property_values(crate, owner, type, name_prefix = nil, &value_of)
          type.extended_metadata_attributes.flat_map do |attribute|
            value = value_of.call(attribute)
            next [] if value.blank?

            name = [name_prefix, attribute.label.presence || attribute.title].compact.join('.')
            if attribute.linked_extended_metadata_or_multi?
              nested_property_values(crate, owner, attribute, name, value)
            else
              [property_value(crate, owner, name, value, attribute)]
            end
          end
        end

        # Nested records are plain hashes keyed by accessor name; several records under one
        # attribute are numbered so their ids stay distinct.
        def nested_property_values(crate, owner, attribute, name, value)
          records = value.is_a?(Array) ? value : [value]
          records.flat_map.with_index(1) do |record, index|
            nested_name = records.size > 1 ? "#{name}.#{index}" : name
            property_values(crate, owner, attribute.linked_extended_metadata_type, nested_name) do |nested|
              record[nested.accessor_name]
            end
          end
        end

        def property_value(crate, owner, name, value, attribute)
          id = "##{owner.prefix}-#{name.parameterize}"
          entity = ::ROCrate::ContextualEntity.new(crate, id, '@type' => 'PropertyValue')
          set(entity, 'name' => name, 'value' => value, 'propertyID' => property_id(attribute, owner.resource))
          crate.add_contextual_entity(entity).reference
        end

        # The attribute's persistent identifier when it has one, otherwise a fragment of the
        # resource's SEEK URL, so every value is identifiable before ontology terms are assigned.
        def property_id(attribute, resource)
          attribute.pid.presence || "#{resource.rdf_seek_id}#extended_metadata/#{attribute.title}"
        end
      end
    end
  end
end
