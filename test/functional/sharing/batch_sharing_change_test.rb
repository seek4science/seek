require 'test_helper'

class BatchSharingChangeTest < ActionController::TestCase
  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    @user = users(:aaron)
    login_as(@user)
    @person = User.current_user.person
  end

  test 'should have the -Bulk sharing permission change- only on your own profile page' do
    get :show, params: { id: @person }
    assert_response :success
    assert_select 'a[href=?]', batch_sharing_permission_preview_person_path, text: /Batch permission changes/

    get :batch_sharing_permission_preview, params: { id: @person.id }
    assert_response :success
    assert_nil flash[:error]

    logout

    get :show, params: { id: @person }
    assert_response :success
    assert_select 'a', text: /Batch permission changes/, count: 0

    get :batch_sharing_permission_preview, params: { id: @person.id }
    assert_redirected_to :root
    assert_equal flash[:error], 'You are not permitted to perform this action.'
  end


  test 'should show all the items which can change sharing permissions' do

    login_as(@user)
    person = User.current_user.person
    bulk_create_sharing_assets        # Creates one of each everything
    Sop.last.assays = [Assay.last]    # Links sop with isa structure

    # Add manageable df link to isa that cannot be managed
    other_user = FactoryBot.create(:user).person
    o_inv=FactoryBot.create(:investigation, contributor: other_user)
    o_study = FactoryBot.create(:study, investigation: o_inv, contributor: other_user)
    o_assay = FactoryBot.create(:assay, study: o_study, contributor: other_user, policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE))
    df = FactoryBot.create(:data_file, contributor: @user.person, assay_ids: [o_assay.id])
    assert df.can_manage?
    assert !o_assay.can_manage?
    assert !o_study.can_manage?
    assert !o_inv.can_manage?

    # Items that can be changed should be 1 of each except events(+1), investigations(+2), studies(+1) and datafiles(+1)
    related_items_count = Seek::Util.authorized_types.length + 5

    get :batch_sharing_permission_preview, params: { id: person.id }
    assert_response :success
    assert_select 'h1', text: /items related to/, count: 1 do
      assert_select 'a[href=?]', "/people/#{person.id}", text: /#{person.name}/, count: 1
    end
    assert_select 'div#sorted_by_type', count: 1 do
      # Should see all items with policies
      assert_select '.type_and_title', count: related_items_count
      assert_select '[type=checkbox]', count: related_items_count
    end
    assert_select 'div#sorted_by_isa', count: 1 do
      # Should see all items with policies and blocked ISA
      assert_select '.type_and_title', count: related_items_count + 3
      assert_select '[type=checkbox]', count: related_items_count
      assert_select '.parent-btn-checkbox.cant_manage', count: 1
      assert_select '.parent-btn-checkbox.not_visible', count: 2
      assert_select '.type_and_title', text: /This item is hidden to you/, count: 2 # Doesn't even show title
    end

  end


  test 'should list the selected items' do

    params = { publish: {} }
    params= params.merge(id: @person.id)
    post :batch_change_permission_for_selected_items, params: params
    assert_response :redirect
    assert_equal flash[:error], 'Please choose at least one item!'


    # selected items don't include downloadable items
    params[:publish] = {}
    event = FactoryBot.create(:event, contributor: @person)
    params[:publish][event.class.name] ||= {}
    params[:publish][event.class.name][event.id.to_s] = '1'

    post :batch_change_permission_for_selected_items, params: params.merge(id: @person.id)
    assert_select '.highlight-colour', count: 0
    assert_select '.type_and_title', count: 1 do
      assert_select 'a[href=?]', event_path(event), text:/#{event.title}/
    end

    #selected items include downloadable items
    params[:publish] = {}
    model = FactoryBot.create(:model, contributor: @person, projects: [@person.projects.first])
    params[:publish][model.class.name] ||= {}
    params[:publish][model.class.name][model.id.to_s] = '1'

    df = data_with_isa
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'
    post :batch_change_permission_for_selected_items, params: params.merge(id: @person.id)

    assert_select '.type_and_title', count: 2 do
      assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/
      assert_select 'a[href=?]', model_path(model), text: /#{model.title}/
      assert_select '.icon', count: 2
    end
    assert_select '.highlight-colour', count: 1, text: /Download/
  end


  test 'should bulk change sharing permissions of selected items' do

    model = FactoryBot.create(:model, contributor: @person, projects: [@person.projects.first], policy: FactoryBot.create(:private_policy))
    df = FactoryBot.create(:data_file, contributor: @person, policy: FactoryBot.create(:private_policy))

    other_person = people(:quentin_person)

    # a private asset can not be viewed or downloaded by other people
    assert !model.can_view?(other_person)
    assert !df.can_view?(other_person)
    assert !model.can_download?(other_person)
    assert !df.can_download?(other_person)


    params = { publish: {} }
    params[:publish][model.class.name] ||= {}
    params[:publish][model.class.name][model.id.to_s] = '1'
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'
    params[:publish]['Banana'] = { '123': '1' } # Should be ignored

    # batch change sharing policy and grant other_people manage right
    params[:policy_attributes] = {access_type: Policy::NO_ACCESS, permissions_attributes: {'1': {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}}
    params= params.merge(id: @person.id)
    post :batch_sharing_permission_changed, params: params
    assert_response :success

    assert model.can_view?(other_person)
    assert df.can_view?(other_person)
    assert model.can_download?(other_person)
    assert df.can_download?(other_person)

    logout
    assert !model.can_view?
    assert !df.can_view?
    assert !model.can_download?
    assert !df.can_download?

  end

  test 'should notify gatekeeper and create logs if necessary' do

    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    refute_empty gatekeeper.projects
    a_person = FactoryBot.create(:person, project: gatekeeper.projects.first)
    login_as(a_person.user)

    gk_model = FactoryBot.create(:model, contributor: a_person, title: 'GKModel', projects: [gatekeeper.projects.first], policy: FactoryBot.create(:private_policy))
    gk_df = FactoryBot.create(:data_file, contributor: a_person, title: 'GKDataFile', projects: [gatekeeper.projects.first], policy: FactoryBot.create(:private_policy))
    df = FactoryBot.create(:data_file, contributor: a_person, title: 'OpenDataFile', projects: [@person.projects.first], policy: FactoryBot.create(:private_policy))

    assert gk_model.policy.access_type == Policy::NO_ACCESS
    assert gk_df.policy.access_type == Policy::NO_ACCESS
    assert df.policy.access_type == Policy::NO_ACCESS
    assert gk_model.gatekeeper_required?
    assert gk_df.gatekeeper_required?
    assert !df.gatekeeper_required?

    # Batch change sharing policy params
    params = { publish: {} }
    params[:publish][gk_model.class.name] ||= {}
    params[:publish][gk_model.class.name][gk_model.id.to_s] = '1'
    params[:publish][gk_df.class.name] ||= {}
    params[:publish][gk_df.class.name][gk_df.id.to_s] = '1'
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'
    params = params.merge(id: a_person.id)

    # Can't make public without involving gatekeeper
    params[:policy_attributes] = { access_type: Policy::ACCESSIBLE }
    assert_enqueued_emails(2) do
      post :batch_sharing_permission_changed, params: params
      assert_response :success
      # Flash correctly displayed
      assert_select 'div#notice_flash', count: 1 do
        assert_select 'ul#ok', count: 1 do
          assert_select 'li', text: df.title, count: 1
        end
        assert_select 'ul#gk', count: 1 do
          assert_select 'li', count: 2
          assert_select 'li', text: gk_df.title
          assert_select 'li', text: gk_model.title
        end
      end
    end
    gk_model.reload
    gk_df.reload
    df.reload
    # Policies and publish logs correctly saved
    assert gk_model.policy.access_type == Policy::NO_ACCESS
    assert gk_df.policy.access_type == Policy::NO_ACCESS
    assert df.policy.access_type == Policy::ACCESSIBLE
    assert gk_model.is_waiting_approval?
    assert gk_df.is_waiting_approval?
    assert df.is_published?

    # Can make visible without involving gatekeeper
    params[:policy_attributes] = { access_type: Policy::VISIBLE }
    assert_enqueued_emails(0) do
      post :batch_sharing_permission_changed, params: params
      assert_response :success
      # Flash correctly displayed
      assert_select 'div#notice_flash', count: 1 do
        assert_select 'ul#ok', count: 1 do
          assert_select 'li', count: 3
          assert_select 'li', text: df.title
          assert_select 'li', text: gk_df.title
          assert_select 'li', text: gk_model.title
        end
        assert_select 'ul#gk', count: 0
      end
    end
    gk_model.reload
    gk_df.reload
    df.reload
    # Policies correctly saved
    assert gk_model.policy.access_type == Policy::VISIBLE
    assert gk_df.policy.access_type == Policy::VISIBLE
    assert df.policy.access_type == Policy::VISIBLE

    # Can hide from public without involving gatekeeper
    params[:policy_attributes] = { access_type: Policy::NO_ACCESS }
    assert_enqueued_emails(0) do
      post :batch_sharing_permission_changed, params: params
      assert_response :success
      # Flash correctly displayed
      assert_select 'div#notice_flash', count: 1 do
        assert_select 'ul#ok', count: 1 do
          assert_select 'li', count: 3
          assert_select 'li', text: df.title
          assert_select 'li', text: gk_df.title
          assert_select 'li', text: gk_model.title
        end
        assert_select 'ul#gk', count: 0
      end
    end
    gk_model.reload
    gk_df.reload
    df.reload
    # Policies correctly saved
    assert gk_model.policy.access_type == Policy::NO_ACCESS
    assert gk_df.policy.access_type == Policy::NO_ACCESS
    assert df.policy.access_type == Policy::NO_ACCESS
  end



  private

  def bulk_create_sharing_assets
    authorized_types = Seek::Util.authorized_types
    authorized_types.collect do |klass|
      FactoryBot.create(klass.name.underscore.to_sym, contributor: User.current_user.person)
    end
  end

  def data_file_for_sharing(owner = users(:datafile_owner))
    FactoryBot.create(:data_file, contributor: owner.person)
  end

  def data_with_isa
    df = data_file_for_sharing
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
