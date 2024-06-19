require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  def setup
    # Create the SampleAttributeTypes
    %i[string_sample_attribute_type sample_multi_sample_attribute_type].map do |type|
      FactoryBot.create(type)
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
end
