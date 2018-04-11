class RestructureSeekResourceSampleJson < ActiveRecord::Migration
  def up
    resource_attribute_types = SampleAttributeType.all.select(&:seek_resource?)

    attributes_type_map = {}

    resource_attribute_types.each do |attribute_type|
      type = attribute_type.base_type_handler.type

      attribute_type.sample_attributes.each do |attr|
        attributes_type_map[attr] = type
      end
    end.flatten.uniq.compact

    sample_types = attributes_type_map.keys.map(&:sample_type).flatten.uniq.compact

    sample_types.each do |type|
      puts "Fixing #{type.samples.count} #{type.title} samples:"
      type.samples.each do |sample|
        data = sample.data
        attributes_type_map.each do |attr, resource_type|
          value = data[attr.hash_key]
          if value.is_a?(Fixnum) || value.is_a?(String)
            data[attr.hash_key] = value # This will re-run the pre-processing step
          elsif value.is_a?(Hash) && !value.key?(:type) && !value.key?('type') # Add missing "type"
            value['type'] = resource_type
            data.orig_set_value(attr.hash_key, value)
          end

          sample.update_column(:json_metadata, data.to_json)
        end
        print '.'
      end
      puts
    end
  end

  def down # Revert SEEK sample attributes back to being just IDs
    seek_sample_attribute_types = SampleAttributeType.all.select(&:seek_sample?)

    attributes_type_map = {}

    seek_sample_attribute_types.each do |attribute_type|
      type = attribute_type.base_type_handler.type

      attribute_type.sample_attributes.each do |attr|
        attributes_type_map[attr] = type
      end
    end.flatten.uniq.compact

    sample_types = attributes_type_map.keys.map(&:sample_type).flatten.uniq.compact

    sample_types.each do |type|
      puts "Unfixing #{type.samples.count} #{type.title} samples:"
      type.samples.each do |sample|
        data = sample.data
        attributes_type_map.each_key do |attr|
          value = data[attr.hash_key]
          if value.is_a?(Hash)
            data.orig_set_value(attr.hash_key, value['id'])
          end

          sample.update_column(:json_metadata, data.to_json)
        end
        print '.'
      end
      puts
    end
  end
end
