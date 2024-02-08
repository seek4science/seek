require 'test_helper'

class GitFormatTest < ActionDispatch::IntegrationTest
  test 'gets appropriate response format from git controller' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    git_version = workflow.git_version
    disable_authorization_checks do
      git_version.add_file('dmp.json', open_fixture_file('dmp.json'))
      git_version.add_file('file', open_fixture_file('file'))
      git_version.add_file('html_file.html', open_fixture_file('html_file.html'))
      git_version.save!
    end

    ['dmp.json', 'file', 'html_file.html', 'diagram.png'].each do |path|
      # Default to HTML response
      get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => '*/*' }
      assert_response :success
      assert_equal 'text/html; charset=utf-8', response.headers['Content-Type']
      assert response.body.start_with?('<!doctype html>')

      # Even without any Accept
      get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => '' }
      assert_response :success
      assert_equal 'text/html; charset=utf-8', response.headers['Content-Type']
      assert response.body.start_with?('<!doctype html>')

      # Default headers
      get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5'}
      assert_response :success
      assert_equal 'text/html; charset=utf-8', response.headers['Content-Type']
      assert response.body.start_with?('<!doctype html>')

      # Explicit HTML
      get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => 'text/html' }
      assert_response :success
      assert_equal 'text/html; charset=utf-8', response.headers['Content-Type']
      assert response.body.start_with?('<!doctype html>')

      # Permit JSON response
      get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => 'application/json' }
      assert_response :success
      assert_equal 'application/vnd.api+json; charset=utf-8', response.headers['Content-Type']
      assert_equal path, JSON.parse(response.body)['path']

      # Otherwise unrecognized format
      assert_raises(ActionController::UnknownFormat) do
        get "/workflows/#{workflow.id}/git/1/blob/#{path}", headers: { 'Accept' => 'application/zip' }
      end
    end
  end
end