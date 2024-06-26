require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  def setup
    # Create the SampleAttributeTypes
    # The title MUST be set manually!
    FactoryBot.create(:string_sample_attribute_type, title: 'String attribute type 1')
    FactoryBot.create(:sample_multi_sample_attribute_type, title: 'Sample multi attribute type 1')

    # Create the ISA Tags
    %i[source_isa_tag sample_isa_tag protocol_isa_tag source_characteristic_isa_tag sample_characteristic_isa_tag 
       other_material_isa_tag other_material_characteristic_isa_tag data_file_isa_tag parameter_value_isa_tag
       data_file_comment_isa_tag default_isa_tag].map do |tag|
      FactoryBot.create(tag)
    end

    # Set isa_json_compliance_enabled to true
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    # Set isa_json_compliance_enabled back to false
    Seek::Config.isa_json_compliance_enabled = false
  end

  test 'perform' do
    # Copy the JSON file to the source_types directory
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'test_templates.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_nothing_raised do
      assert_difference('Template.count', 4) do
        PopulateTemplatesJob.perform_now
      end
    end
  end

  test 'perform with json containing invalid sample attribute type' do
    # Copy the JSON file to the source_types directory
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'invalid_attribute_type_templates.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_no_difference('Template.count') do
      assert_raises(RuntimeError, 
'<ul><li>The property \'#/data/0/data/1/dataType\' value \"Invalid String attribute type 1\" did not match one of the following values: String attribute type 1, Sample multi attribute type 1 in schema file:///home/kepel/projects/seek/lib/seek/isa_templates/template_attributes_schema_test.json#</li><li>Could not find a Sample Attribute Type named \'Invalid String attribute type 1\'</li></ul>') do
        PopulateTemplatesJob.perform_now
      end
    end
  end

  test 'perform with json containing invalid ISA tag' do
    # Copy the JSON file to the source_types directory
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'invalid_isa_tag_templates.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_no_difference('Template.count') do
      assert_raises(StandardError) do
        PopulateTemplatesJob.perform_now
      end
    end
  end

end
