require 'test_helper'

class TemplatesHelperTest < ActionView::TestCase

    def setup
        @template = FactoryBot.create(:max_template, title: "My template", policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE ))
    end
    
    test 'should load templates' do
        templates = load_templates
        
        assert_not_nil templates
        assert_not_equal 0, templates.length

        test_template = templates.find { |i| i[:title] == "My template"}
        assert_not_nil test_template

        assert_equal 'My template', test_template[:title]
        assert_equal 'study sample', test_template[:level]
        assert_equal 'arrayexpress', test_template[:group]
        assert_equal @template.template_attributes.length, test_template[:attributes].length
    end

    test 'should not load the Minimal ISA templates when applying to a Sample Type' do
      %i[
      isa_source_template
      isa_sample_collection_template
      isa_assay_material_template
      isa_assay_data_file_template
      ].each do |t|
        FactoryBot.create(t, group: Seek::ISATemplates::TemplateGroup::ISA_MINIMAL_STARTER,
                          policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE ))
      end

      templates_for_sample_types = load_templates(true)
      assert_equal 1, templates_for_sample_types.length
      assert_equal 1, Template.for_sample_type_creation.length
      assert_equal 5, Template.count
      assert templates_for_sample_types.none? { |t| t[:group] == Seek::ISATemplates::TemplateGroup::ISA_MINIMAL_STARTER }

      templates_for_templates = load_templates
      assert_equal templates_for_templates.length, Template.count
    end

    test 'should not show private templates' do
        assert_equal Template.all.length, load_templates.length
        FactoryBot.create(:min_template, policy: FactoryBot.create(:policy, access_type: Policy::NO_ACCESS ))
        assert_not_equal Template.all.length, load_templates.length
    end
end
