class AddRdfValueTypeToSampleAttributeTypes < ActiveRecord::Migration[7.2]
  def change
    add_column :sample_attribute_types, :rdf_value_type, :string
    add_column :sample_attribute_types, :rdf_datatype, :string
  end
end
