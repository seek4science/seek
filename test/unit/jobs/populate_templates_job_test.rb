require 'test_helper'

class PopulateTemplatesJobTest < ActiveSupport::TestCase
  def setup
    %i[string_sample_attribute_type sample_multi_sample_attribute_type].map do |type|
      FactoryBot.create(type)
    end
  end

  test 'perform' do
    # Copy the JSON file to the source_types directory
    src = Rails.root.join('test', 'fixtures', 'files', 'upload_json_sample_type_template', 'test_templates.json')
    dest = Seek::Config.append_filestore_path('source_types')
    FileUtils.cp(src, dest)

    with_config_value(:isa_json_compliance_enabled, true) do
      assert_nothing_raised do
        PopulateTemplatesJob.perform_now
      end
    end
  end
end
