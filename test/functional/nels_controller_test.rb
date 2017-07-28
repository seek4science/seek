require 'test_helper'

class NelsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  setup do
    person = Factory(:person)
    @user = person.user
    @project = person.projects.first
    @project.settings['nels_enabled'] = true

    @user.oauth_sessions.where(provider: 'NeLS').create(access_token: 'fake-access-token', expires_at: 1.week.from_now)

    login_as(@user)

    study = Factory(:study, investigation: Factory(:investigation, project_ids: [@project.id]))
    @assay = Factory(:assay, contributor: person, study: study)

    @project_id = 91123122
    @dataset_id = 91123528
    @subtype = 'reads'
    @reference = 'xMTEyMzEyMjoxMTIzNTI4OnJlYWRz'
  end

  test 'can get browser' do
    VCR.use_cassette('nels/get_user_info') do
      get :browser, assay_id: @assay.id
    end

    assert_response :success
    assert_select '#nels-tree'
  end

  test 'redirects to NeLS login if token expired' do
    session = @user.oauth_sessions.where(provider: 'NeLS').last
    session.update_column(:expires_at, 1.day.ago)
    oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                            Seek::Config.nels_client_secret,
                                            nels_oauth_callback_url,
                                            "assay_id:#{@assay.id}")

    VCR.use_cassette('nels/get_user_info') do
      get :browser, assay_id: @assay.id
    end

    assert_redirected_to oauth_client.authorize_url
  end

  test 'can load projects' do
    VCR.use_cassette('nels/get_projects') do
      get :projects, format: :json
    end

    assert_response :success
    assert_equal 2, JSON.parse(response.body).length
  end

  test 'can load datasets' do
    VCR.use_cassette('nels/get_datasets') do
      get :datasets, format: :json, id: @project_id
    end

    assert_response :success
    assert_equal 2, JSON.parse(response.body).length
  end

  test 'can load dataset' do
    VCR.use_cassette('nels/get_dataset') do
      get :dataset, project_id: @project_id, dataset_id: @dataset_id
    end

    assert_response :success
    assert_select 'li.list-group-item', count: 2
  end
end
