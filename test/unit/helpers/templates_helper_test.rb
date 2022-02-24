require 'test_helper'

class TemplatesHelperTest < ActionView::TestCase
    def setup
        @template = Factory(:max_template, policy: Factory(:policy, access_type: Policy::VISIBLE ))
    end
    
    test 'should load templates' do
        templates = load_templates
        assert_equal 1, templates.length
        test_template = templates[0]
        assert_equal 'A Maximal Template', test_template[:title]
        assert_equal 'assay', test_template[:level]
        assert_equal 'arrayexpress', test_template[:group]
        assert_equal @template.template_attributes.length, test_template[:attributes].length
    end

    test 'should show public and authorized templates' do
        t = Factory(:template)
        templates = load_templates
        assert_equal Template.all.length, 2
        assert_equal templates.length, 1
    end
end
