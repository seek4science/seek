require 'test_helper'
require 'integration/api_test_helper'

class SopCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'sop'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: @current_person)
    study = Factory(:study, investigation: investigation, contributor: @current_person)
    @assay = Factory(:assay, study: study, contributor: @current_person)
    @creator = Factory(:person)

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_sop.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    sop = Factory(:sop, policy: Factory(:public_policy), contributor: @current_person, creators: [@creator])
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: sop.id})
  end

  def populate_extra_relationships(hash = nil)
    extra_relationships = {}
    extra_relationships[:submitter] = { data: [{ id: @current_person.id.to_s, type: 'people' }] }
    extra_relationships[:people] = { data: [{ id: @current_person.id.to_s, type: 'people' },
                                            { id: @creator.id.to_s, type: 'people' }] }
    extra_relationships.with_indifferent_access
  end

  test 'can add content to API-created sop' do
    sop = Factory(:api_pdf_sop, contributor: @current_person)

    assert sop.content_blob.no_content?
    assert sop.can_download?(@current_user)
    assert sop.can_edit?(@current_user)

    original_md5 = sop.content_blob.md5sum
    put sop_content_blob_path(sop, sop.content_blob), nil,
        'Accept' => 'application/json',
        'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf'))

    assert_response :success
    blob = sop.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end
end
