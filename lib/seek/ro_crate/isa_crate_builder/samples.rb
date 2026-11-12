module Seek
  module RoCrate
    class ISACrateBuilder
      # Sample entities for the samples of an assay, with their attributes as PropertyValue entities.
      module Samples
        private

        # The samples the user can view, as references to Sample entities.
        def sample_references(crate, assay)
          viewable(assay.samples).map { |sample| sample_entity(crate, sample).reference }
        end

        # One Sample entity per sample however many assays use it.
        def sample_entity(crate, sample)
          @samples ||= {}
          @samples[sample.id] ||= begin
            entity = ::ROCrate::ContextualEntity.new(crate, "#sample-#{sample.id}", '@type' => 'Sample')
            set(entity, 'name' => sample.title,
                        'identifier' => sample.rdf_seek_id,
                        'additionalProperty' => characteristic_references(crate, sample))
            crate.add_contextual_entity(entity)
          end
        end

        # Every filled attribute except the title (which is the sample's name). SEEK does not record
        # whether an attribute is a characteristic or a factor, so all are CharacteristicValue.
        def characteristic_references(crate, sample)
          sample.sample_type.sample_attributes.reject(&:is_title?).filter_map do |attribute|
            value = sample.get_attribute_value(attribute)
            next if value.blank?

            characteristic(crate, sample, attribute, value).reference
          end
        end

        def characteristic(crate, sample, attribute, value)
          id = "#sample-#{sample.id}-#{attribute.title.parameterize}"
          entity = ::ROCrate::ContextualEntity.new(crate, id, '@type' => 'PropertyValue',
                                                              'additionalType' => 'CharacteristicValue')
          set(entity, 'name' => attribute.title, 'value' => value, 'propertyID' => attribute.pid.presence)
          set(entity, unit_properties(attribute.unit)) if attribute.unit
          crate.add_contextual_entity(entity)
        end

        def unit_properties(unit)
          { 'unitCode' => unit.symbol, 'unitText' => unit.title.presence || unit.comment }
        end
      end
    end
  end
end
