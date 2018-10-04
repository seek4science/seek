class AddNcbiSampleAttributeType < ActiveRecord::Migration
  def up
    ncbi_type = SampleAttributeType.find_or_initialize_by(title:'NCBI ID')
    ncbi_type.update_attributes(base_type: Seek::Samples::BaseType::STRING, regexp: '[0-9]+', placeholder: '23234', resolution:'https://identifiers.org/taxonomy/\\0')
  end

  def down
    ncbi_type = SampleAttributeType.find_or_initialize_by(title:'NCBI ID')
    ncbi_type.delete()
  end
end
