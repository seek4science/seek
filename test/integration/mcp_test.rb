require 'test_helper'
require 'minitest/mock'

class McpTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  test 'initialize handshake' do
    mcp_request 'initialize', {
      protocolVersion: '2025-06-18',
      capabilities: {},
      clientInfo: { name: 'test', version: '1.0' }
    }

    assert_response :success
    assert_equal 'seek_mcp_server', response.parsed_body.dig('result', 'serverInfo', 'name')
    assert_match /\d\..+/, response.parsed_body.dig('result', 'serverInfo', 'version')
  end

  test 'lists registered tools' do
    mcp_request 'tools/list'

    names = response.parsed_body.dig('result', 'tools').map { _1['name'] }
    assert_includes names, 'search_tool'
  end

  test 'calls a tool' do
    workflows = FactoryBot.create_list(:public_workflow, 3, title: 'Workflow Result')
    Workflow.stub(:solr_cache, -> (q) { workflows.map(&:id) }) do
      mcp_request 'tools/call',
                  { name: 'search_tool', arguments: { query: 'test 123', type: 'workflows' } }
    end

    result = response.parsed_body['result']
    assert_not result[:isError]
    assert_includes result[:content].first[:text], 'Workflow Result - http://'
  end

  test 'notifications get 202 with no body' do
    mcp_request 'notifications/initialized', id: nil
    assert_response :accepted
  end

  test 'GET is rejected with 405' do
    get '/mcp', headers: @auth
    assert_response :method_not_allowed
  end

  private

  def mcp_request(method, params = {}, id: 1, headers: {})
    body = { jsonrpc: '2.0', method: method, params: params }
    body[:id] = id if id # omit id to send a notification

    post '/mcp', params: body.to_json, headers: {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json, text/event-stream'
    }.merge(headers)
  end
end
