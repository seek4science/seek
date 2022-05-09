require 'test_helper'

class SopApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: current_person)
    study = Factory(:study, investigation: investigation, contributor: current_person)
    @assay = Factory(:assay, study: study, contributor: current_person)
    @creator = Factory(:person)
    @sop = Factory(:sop, policy: Factory(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'can add content to API-created sop' do
    sop = Factory(:api_pdf_sop, contributor: current_person)

    assert sop.content_blob.no_content?
    assert sop.can_download?(@current_user)
    assert sop.can_edit?(@current_user)

    original_md5 = sop.content_blob.md5sum
    put sop_content_blob_path(sop, sop.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = sop.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'preserves policy on update' do
    policy = Factory(:private_policy)
    permissions = [
      Factory(:permission, policy: policy, contributor: Factory(:person), access_type: Policy::MANAGING),
      Factory(:permission, policy: policy, contributor: Factory(:project), access_type: Policy::ACCESSIBLE),
      Factory(:permission, policy: policy, contributor: Factory(:programme), access_type: Policy::VISIBLE),
      Factory(:permission, policy: policy, contributor: Factory(:institution), access_type: Policy::VISIBLE),
      Factory(:permission, policy: policy, contributor: Factory(:work_group), access_type: Policy::EDITING),
      Factory(:permission, policy: policy, contributor: Factory(:favourite_group), access_type: Policy::MANAGING)
    ]
    policy.reload
    assert_equal Permission::PRECEDENCE.sort, permissions.map(&:contributor_type).sort, 'Should be one of each permission type'
    sop = Factory(:sop, contributor: current_person, policy: policy)
    original_policy = sop.reload.policy
    original_permissions = original_policy.permissions.to_a

    get sop_path(sop, format: :json)
    assert_response :success

    parsed_policy = JSON.parse(@response.body)['data']['attributes']['policy']

    validate_json parsed_policy.to_json, "#/definitions/policy"

    to_patch = {
      data: {
        type: "sops",
        id: "#{sop.id}",
        attributes: {
          policy: parsed_policy
        }
      }
    }

    patch sop_path(sop, format: :json), params: to_patch, as: :json
    assert_response :success

    updated_policy = JSON.parse(@response.body)['data']['attributes']['policy']

    assert_equal parsed_policy, updated_policy
    assert_equal original_policy, sop.reload.policy
    compare = proc { |p| "#{p.contributor_type}:#{p.contributor_id} - #{p.access_type}" }
    assert_equal original_permissions.map(&compare).sort, sop.reload.policy.permissions.to_a.map(&compare).sort
  end
end
