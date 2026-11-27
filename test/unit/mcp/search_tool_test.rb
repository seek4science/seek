# test/mcp/search_tool_test.rb
require 'test_helper'
require 'minitest/mock'

class SearchToolTest < ActiveSupport::TestCase
  test 'searches for workflows' do
    workflows = FactoryBot.create_list(:public_workflow, 3, title: 'Workflow Result')
    result = nil
    Workflow.stub(:solr_cache, -> (q) { workflows.map(&:id) }) do
      result = Tools::SearchTool.call(query: 'test123', type: 'workflows', server_context: { }).to_h
    end

    refute result[:isError]
    assert_includes result[:content].first[:text], 'Workflow Result - http://'
  end

  test 'errors if searching for disabled type' do
    result = nil
    with_config_value(:data_files_enabled, false) do
      result = Tools::SearchTool.call(query: 'test123', type: 'data_files', server_context: { }).to_h
    end

    assert result[:isError]
    assert_includes result[:content].first[:text], 'ERROR: data_files is not a valid search type'
  end

  test 'disabled if search disabled' do
    assert Tools::SearchTool.enabled?

    with_config_value(:solr_enabled, false) do
      refute Tools::SearchTool.enabled?
    end
  end

  test 'schema does not list disabled types' do
    with_config_value(:data_files_enabled, true) do
      assert_includes Tools::SearchTool.build.to_h.dig(:inputSchema, :properties, :type, :enum), 'data_files'
    end

    with_config_value(:data_files_enabled, false) do
      assert_not_includes Tools::SearchTool.build.to_h.dig(:inputSchema, :properties, :type, :enum), 'data_files'
    end
  end
end
