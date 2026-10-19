require 'test_helper'

class SinglePublishingTest < ActionController::TestCase
  tests DataFilesController


  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test 'should be able to do publish when publishable' do
    df = data_with_isa
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    df.projects << gatekeeper.projects.first
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'

    get :show, params: { id: df }
    assert_response :success
    assert_select 'a', text: /Publish #{I18n.t('data_file')}/

    get :check_related_items, params: { id: df }
    assert_response :success
    assert_nil flash[:error]

    get :publish_related_items, params: { id: df }
    assert_response :success
    assert_nil flash[:error]

    get :check_gatekeeper_required, params: { id: df }
    assert_response :success
    assert_nil flash[:error]

    post :publish, params: { id: df }
    assert_response :redirect
    assert_nil flash[:error]
  end

  test 'should not be able to do publish when not publishable' do
    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_viewable_policy))
    assert df.can_view?, 'The datafile must be viewable for this test to be meaningful'
    assert !df.can_publish?, 'The datafile must not be manageable for this test to succeed'

    get :show, params: { id: df }
    assert_response :success
    assert_select 'a', text: /Publish #{I18n.t('data_file')}/, count: 0

    get :check_related_items, params: { id: df }
    assert_redirected_to :root
    assert flash[:error]

    get :publish_related_items, params: { id: df }
    assert_redirected_to :root
    assert flash[:error]

    get :check_gatekeeper_required, params: { id: df }
    assert_redirected_to :root
    assert flash[:error]

    post :publish, params: { id: df }
    assert_redirected_to :root
    assert flash[:error]
  end

  test 'get check_related_items' do
    df = data_with_isa
    assert df.can_publish?, 'The datafile must be publishable for this test to succeed'

    get :check_related_items, params: { id: df.id }
    assert_response :success

    assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/
    assert_select 'div[style="display:none"]' do
      assert_select "input[type='checkbox'][checked='checked'][id=?]", "publish_DataFile_#{df.id}"
    end
  end

  test 'get publish_related_items' do
    df = data_with_isa
    assay = df.assays.first
    study = assay.study
    investigation = study.investigation

    notifying_df = assay.data_files.reject { |d| d == df }.first
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = users(:datafile_owner).person
    gatekept_project = gatekeeper.projects.first
    non_gatekept_project = person.projects.first
    person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))
    request_publishing_df = FactoryBot.create(:data_file,
                                    projects: [gatekept_project],
                                    contributor: person,
                                    assays: [assay])
    publishing_df = FactoryBot.create(:data_file,
                            projects: [non_gatekept_project],
                            contributor: person,
                            assays: [assay])

    assert_not_nil assay, 'There should be an assay associated'
    assert df.can_publish?, 'The datafile must be publishable for this test to succeed'
    assert request_publishing_df.can_publish?, 'The datafile must not be publishable for this test to succeed'
    assert !notifying_df.can_publish?, 'The datafile must not be publishable for this test to succeed'

    get :publish_related_items, params: { id: df.id }
    assert_response :success

    assert_select '.type_and_title', text: /Investigation/, count: 1 do
      assert_select 'a[href=?]', investigation_path(investigation), text: /#{investigation.title}/
    end
    assert_select '.parent-btn-checkbox' do
      assert_select "input[type='checkbox'][id=?]", "publish_Investigation_#{investigation.id}"
    end

    assert_select '.type_and_title', text: /Study/, count: 1 do
      assert_select 'a[href=?]', study_path(study), text: /#{study.title}/
    end
    assert_select '.parent-btn-checkbox' do
      assert_select "input[type='checkbox'][id=?]", "publish_Study_#{study.id}"
    end

    assert_select '.type_and_title', text: /Assay/, count: 1 do
      assert_select 'a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
    assert_select '.parent-btn-checkbox' do
      assert_select "input[type='checkbox'][id=?]", "publish_Assay_#{assay.id}"
    end

    assert_select '.type_and_title', text: /#{I18n.t('data_file')}/, count: 4 do
      assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/
      assert_select 'a[href=?]', data_file_path(publishing_df), text: /#{publishing_df.title}/
      assert_select 'a[href=?]', data_file_path(request_publishing_df), text: /#{request_publishing_df.title}/
      assert_select 'a[href=?]', data_file_path(notifying_df), text: /#{notifying_df.title}/
    end
    assert_select '.parent-btn-checkbox' do
      assert_select "input[type='checkbox'][id=?]", "publish_DataFile_#{publishing_df.id}"
      assert_select "input[type='checkbox'][id=?]", "publish_DataFile_#{request_publishing_df.id}"
    end

    assert_select '.parent-btn-checkbox.btn-warning[data-tooltip=?]', 'You do not have permission to manage this item.', count: 1
  end

  test 'split-button recursive selection' do
    datafile111 = data_with_isa
    assay11 = datafile111.assays.first
    study1 = assay11.study
    investigation = study1.investigation
    person = users(:datafile_owner).person

    datafile112 = FactoryBot.create(:data_file, assays: [assay11], contributor: person)
    assay12 = FactoryBot.create(:assay, investigation: investigation, study: study1, contributor: person)
    datafile121 = FactoryBot.create(:data_file, assays: [assay12], contributor: person)
    study2 = FactoryBot.create(:study, investigation: investigation, contributor: person)
    assay21 = FactoryBot.create(:assay, investigation: investigation, study: study2, contributor: person)

    should_have_dropdown = [investigation, study1, assay11, assay12, study1, study2]
    should_not_have_dropdown = [datafile111, datafile112, datafile121, assay21]

    get :publish_related_items, params: { id: datafile111.id }
    assert_response :success

    # split-button dropdown menu shown for tree branches
    should_have_dropdown.each do |asset|
      assert_select '.isa-tree[data-asset-id=?]', "#{asset.class.name}_#{asset.id}", count: 1 do
        assert_select '.parent-btn-dropdown', count: 1
        assert_select '.dropdown-menu', count: 1 do
          assert_select 'li', count: 2 do
            assert_select 'a.batch-selection-select-children', text: /Select this item and all of its sub-items./, count: 1 do
              assert_select 'img[src=?]', '/assets/checkbox_select_all.svg'
            end

            assert_select 'a.batch-selection-deselect-children', text: /Deselect this item and all of its sub-items./, count: 1 do
              assert_select 'img[src=?]', '/assets/checkbox_deselect_all.svg'
            end
          end
        end
      end
    end
    # split-button dropdown menu not shown for tree leafs
    should_not_have_dropdown.each do |asset|
      assert_select '.isa-tree[data-asset-id=?]', "#{asset.class.name}_#{asset.id}", count: 1 do
        assert_select '.parent-btn-dropdown', count: 0
        assert_select '.dropdown-menu', count: 0
      end
    end
  end

  test 'get check_gatekeeper_required' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = User.current_user.person
    gatekept_project = gatekeeper.projects.first
    non_gatekept_project = person.projects.first
    person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))

    df = FactoryBot.create(:data_file, projects: [gatekept_project], contributor: person)
    model = FactoryBot.create(:model, projects: [gatekept_project], contributor: person)
    sop = FactoryBot.create(:sop, projects: [non_gatekept_project], contributor: person)
    assert df.gatekeeper_required?, "This datafile must require gatekeeper's approval for the test to succeed"
    assert model.gatekeeper_required?, "This model must require gatekeeper's approval for the test to succeed"
    assert !sop.gatekeeper_required?, "This sop must not require gatekeeper's approval for the test to succeed"

    params = { publish: {} }
    [df, model, sop].each do |asset|
      params[:publish][asset.class.name] ||= {}
      params[:publish][asset.class.name][asset.id.to_s] = '1'
    end

    get :check_gatekeeper_required, params: params.merge(id: df.id)
    assert_response :success

    assert_select 'ul#waiting_approval' do
      assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/, count: 1
      assert_select 'a[href=?]', model_path(model), text: /#{model.title}/, count: 1
      assert_select 'a[href=?]', sop_path(sop), text: /#{sop.title}/, count: 0
      assert_select 'a[href=?]', person_path(gatekeeper), text: /#{gatekeeper.name}/, count: 2
    end

    assert_select 'div[style="display:none;"]' do
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_DataFile_#{df.id}"
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_Model_#{model.id}"
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_Sop_#{sop.id}"
    end
  end

  test 'if the asset has no related items, proceed directly to check_gatekeeper_required' do
    df = data_file_for_publishing
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    df.projects << gatekeeper.projects.first
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'

    get :check_related_items, params: { id: df }
    assert_response :success
    assert_select 'ul#waiting_approval', count: 1
    assert_nil flash[:error]

    df.reload
    assert !df.is_published?
  end

  test 'if the asset requires no gatekeeper, proceed to confirmation step' do
    df = data_file_for_publishing
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'
    assert !df.is_published?, 'The data file must not be published for this test to be meaningful'
    assert !df.gatekeeper_required?, 'The data file must need require a gatekeeper for this test to proceed'

    get :check_gatekeeper_required, params: { id: df }
    assert_response :success
    assert_select 'h1', text: /Confirm publishing/
    assert_nil flash[:error]
  end

  test 'do publish' do
    df = data_file_for_publishing
    assert !df.is_published?, 'The data file must not be already published for this test to succeed'
    assert df.can_publish?, 'The data file must be publishable for this test to succeed'

    params = { publish: {} }
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'

    assert_difference('ResourcePublishLog.count', 1) do
      post :publish, params: params.merge(id: df.id)
    end

    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert df.is_published?, 'The data file should be published after doing single_publish'
    refute df.is_waiting_approval?(User.current_user), 'The data file should not be waiting for approval after doing single_publish'
    refute df.is_rejected?, 'The data file should not be be rejected after doing single_publish'

  end

  test "sending publishing request when doing publish for asset that need gatekeeper's approval" do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    person = User.current_user.person
    gatekept_project = gatekeeper.projects.first
    person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))

    df = FactoryBot.create(:data_file, contributor: person, projects: [gatekept_project])
    assert df.can_publish?, 'The data file must be publishable for this test to succeed'
    assert df.gatekeeper_required?, "This datafile must need gatekeeper's approval for the test to succeed'"
    assert !df.is_waiting_approval?(User.current_user), 'The publishing request for this data file must not be sent for this test to succeed'

    params = { publish: {} }
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'

    assert_difference('ResourcePublishLog.count', 1) do
      assert_enqueued_emails 1 do
        post :publish, params: params.merge(id: df.id)
      end
    end

    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert !df.is_published?, 'The data file should not be published after sending publishing request'
    assert df.is_waiting_approval?(User.current_user), 'The publishing request for this data file should be sent after requesting'
  end

  test 'do publish together with ISA' do
    df = data_with_isa
    assays = df.assays
    params = { publish: {} }
    non_owned_assets = []
    assays.each do |a|
      assert !a.is_published?, 'This assay should not be public for the test to work'
      assert !a.study.is_published?, 'This assays study should not be public for the test to work'
      assert !a.study.investigation.is_published?, 'This assays investigation should not be public for the test to work'

      params[:publish]['Assay'] ||= {}
      params[:publish]['Assay'][a.id.to_s] = '1'
      params[:publish]['Study'] ||= {}
      params[:publish]['Study'][a.study.id.to_s] = '1'
      params[:publish]['Investigation'] ||= {}
      params[:publish]['Investigation'][a.study.investigation.id.to_s] = '1'

      a.assets.each do |asset|
        assert !asset.is_published?, 'This assays assets should not be public for the test to work'
        params[:publish][asset.class.name] ||= {}
        params[:publish][asset.class.name][asset.id.to_s] = '1'
        non_owned_assets << asset unless asset.can_manage?
      end
    end

    assert !non_owned_assets.empty?, 'There should be non manageable assets included in this test'

    assert_no_enqueued_emails do
      post :publish, params: params.merge(id: df)
    end

    assert_response :redirect

    df.reload

    assert df.is_published?, 'Datafile should now be published'
    df.assays.each do |assay|
      assert assay.is_published?
      assert assay.study.is_published?
      assert assay.study.investigation.is_published?
    end
    non_owned_assets.each { |a| assert !a.is_published?, 'Non manageable assets should not have been published' }
  end

  test 'do publish some' do
    x = group_memberships(:one)
    assert_equal people(:quentin_person), x.person
    refute_nil x.work_group

    person = people(:quentin_person)
    refute person.projects.empty?

    df = data_with_isa

    assays = df.assays

    params = { publish: {} }
    non_publishable_assets = []
    assays.each do |a|
      assert !a.is_published?, 'This assay should not be public for the test to work'
      assert !a.study.is_published?, 'This assays study should not be public for the test to work'
      assert !a.study.investigation.is_published?, 'This assays investigation should not be public for the test to work'

      params[:publish]['Assay'] ||= {}
      params[:publish]['Study'] ||= {}
      params[:publish]['Study'][a.study.id.to_s] = '1'
      params[:publish]['Investigation'] ||= {}

      a.assets.each do |asset|
        assert !asset.is_published?, 'This assays assets should not be public for the test to work'
        params[:publish][asset.class.name] ||= {}
        params[:publish][asset.class.name][asset.id.to_s] = '1' if asset.can_manage?
        non_publishable_assets << asset unless asset.can_publish?
      end
    end

    assert !non_publishable_assets.empty?, 'There should be non publishable assets included in this test'

    assert_no_enqueued_emails do
      post :publish, params: params.merge(id: df)
    end

    assert_response :redirect

    df.reload

    assert df.is_published?, 'Datafile should now be published'
    df.assays.each do |assay|
      assert !assay.is_published?, 'The assay was not requested to be published'
      assert assay.study.is_published?, 'The study should now be published'
      assert !assay.study.investigation.is_published?, 'The investigation was not requested to be published'
    end
    non_publishable_assets.each { |a| assert !a.is_published?, 'Non publishable assets should be filtered out of publish process' }
  end

  test 'get published' do
    df = data_file_for_publishing
    published_items = ["#{df.class.name},#{df.id}"]
    df1 = FactoryBot.create(:data_file)
    published_items << "#{df1.class.name},#{df1.id}"

    df2 = FactoryBot.create(:data_file, contributor: User.current_user.person)
    waiting_for_publish_items = ["#{df2.class.name},#{df2.id}"]

    assert df.can_view?, 'This datafile must be viewable for the test to succeed'
    assert !df1.can_view?, 'This datafile must not be viewable for the test to succeed'
    assert df2.can_view?, 'This datafile must be viewable for the test to succeed'

    get :published, params: { id: df.id, published_items: published_items, waiting_for_publish_items: waiting_for_publish_items }
    assert_response :success

    assert_select 'ul#published' do
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df.title}/, count: 1
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df1.title}/, count: 0
    end

    assert_select 'ul#publish_requested' do
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df2.title}/, count: 1
    end

    assert_select 'ul#notified', count: 0
  end

  private

  def data_file_for_publishing(owner = users(:datafile_owner))
    FactoryBot.create(:data_file, contributor: owner.person)
  end

  def data_with_isa
    df = data_file_for_publishing
    other_user = users(:quentin)
    assay = FactoryBot.create :experimental_assay, contributor: df.contributor,
                                         study: FactoryBot.create(:study, contributor: df.contributor,
                                                                investigation: FactoryBot.create(:investigation, contributor: df.contributor))
    other_persons_data_file = FactoryBot.create(:data_file, contributor: other_user.person, policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE))
    assay.associate(df)
    assay.associate(other_persons_data_file)
    assert !other_persons_data_file.can_manage?
    df
  end
end
