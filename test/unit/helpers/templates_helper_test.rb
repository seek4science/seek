require 'test_helper'

class TemplatesHelperTest < ActionView::TestCase
    def setup
        @template = Factory :max_template
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
end
