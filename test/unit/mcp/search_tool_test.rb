# test/mcp/search_tool_test.rb
require 'test_helper'
require 'minitest/mock'

class SearchToolTest < ActiveSupport::TestCase
  test 'searches for workflows' do
    workflows = FactoryBot.create_list(:public_workflow, 3, title: 'Workflow Result')
    result = nil
    Workflow.stub(:solr_cache, -> (q) { workflows.map(&:id) }) do
      result = Tools::SearchTool.call(query: "test123", type: 'workflows', server_context: { }).to_h
    end

    assert_not result[:isError]
    assert_includes result[:content].first[:text], 'Workflow Result - http://'
  end
end
