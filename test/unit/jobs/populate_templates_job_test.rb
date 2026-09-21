require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  def setup
    # Create the SampleAttributeTypes
    # The title MUST be set manually!
    FactoryBot.create(:string_sample_attribute_type, title: 'String') if SampleAttributeType.find_by(title: 'String').nil?
    FactoryBot.create(:integer_sample_attribute_type, title: 'Integer') if SampleAttributeType.find_by(title: 'Integer').nil?
    FactoryBot.create(:sample_multi_sample_attribute_type, title: 'Registered Sample List') if SampleAttributeType.find_by(title: 'Registered Sample List').nil?

    # Create the ISA Tags
    %i[source_isa_tag sample_isa_tag protocol_isa_tag source_characteristic_isa_tag sample_characteristic_isa_tag 
       other_material_isa_tag other_material_characteristic_isa_tag data_file_isa_tag parameter_value_isa_tag
       data_file_comment_isa_tag default_isa_tag].map do |tag|
      FactoryBot.create(tag)
    end

    # Set isa_json_compliance_enabled to true
    Seek::Config.isa_json_compliance_enabled = true
    @admin = FactoryBot.create(:admin)
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
        PopulateTemplatesJob.perform_now(@admin)
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
'<ul><li>The property \'#/data/0/data/1/dataType\' value \"Invalid String attribute type 1\" did not match one of the following values: ') do
        PopulateTemplatesJob.perform_now(@admin)
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

  test 'perform sets unit on template attribute from json' do
    unit = Unit.find_or_create_by(symbol: 'g')

    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'test_unit_template.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_difference('Template.count', 1) do
      PopulateTemplatesJob.perform_now(@admin)
    end

    weight_attribute = Template.last.template_attributes.find_by(title: 'Weight')
    assert_not_nil weight_attribute
    assert_equal unit, weight_attribute.unit
  end

  test 'perform with missing unit leaves unit blank on template attribute' do
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'test_templates.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_difference('Template.count', 4) do
      PopulateTemplatesJob.perform_now(@admin)
    end

    Template.last.template_attributes.each do |ta|
      assert_nil ta.unit
    end
  end

  test 'perform with json containing invalid unit symbol raises error' do
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'invalid_unit_template.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    assert_no_difference('Template.count') do
      assert_raises(RuntimeError) do
        PopulateTemplatesJob.perform_now(@admin)
      end
    end
  end

end
