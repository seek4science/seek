require 'test_helper'

class TemplatesHelperTest < ActionView::TestCase

    def setup
        @template = FactoryBot.create(:max_template, policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE ))
    end
    
    test 'should load templates' do
        templates = load_templates
        
        assert_not_nil templates
        assert_not_equal 0, templates.length

        test_template = templates.find { |i| i[:title] == "A Maximal Template"}
        assert_not_nil test_template

        assert_equal 'A Maximal Template', test_template[:title]
        assert_equal 'assay', test_template[:level]
        assert_equal 'arrayexpress', test_template[:group]
        assert_equal @template.template_attributes.length, test_template[:attributes].length
    end

    test 'should not show private templates' do
        assert_equal Template.all.length, load_templates.length
        FactoryBot.create(:template, policy: FactoryBot.create(:policy, access_type: Policy::NO_ACCESS ))
        assert_not_equal Template.all.length, load_templates.length
    end
end
