require 'test_helper'

class AttributionsTest < ActionController::TestCase
  # use SopsController, because attributions don't have their own controller
  tests SopsController

  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  def setup
    login_as(:owner_of_my_first_sop)

    @sop1 = FactoryBot.create(:sop)
    @sop2 = FactoryBot.create(:sop)
    @sop3 = FactoryBot.create(:sop)
  end

  def test_should_create_attribution_when_creating_new_sop
    # create a SOP and verify that both SOP and attribution get created
    assert !users(:owner_of_my_first_sop).person.projects.empty?
    assert users(:owner_of_my_first_sop).person.projects.include?(projects(:myexperiment_project))
    assert_difference ['Sop.count', 'Relationship.count'] do
      post :create, params: { sop: { title: 'test_attributions', project_ids: [projects(:myexperiment_project).id] }, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop1.id]]) }
      assert_redirected_to sop_path(assigns(:sop))
    end
  end

  def test_shouldnt_create_duplicated_attribution
    # create a SOP and verify that both SOP and attribution get created
    # (two identical attributions will be posted, but only one needs to be created)
    assert_difference ['Sop.count', 'Relationship.count'] do
      post :create, params: { sop: { title: 'test_attributions', project_ids: [projects(:myexperiment_project).id] }, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop1.id], ['Sop', @sop1.id]]) }
      assert_redirected_to sop_path(assigns(:sop))
    end
  end

  def test_should_remove_attribution_on_update
    # create a SOP / attribution first
    assert_difference ['Sop.count', 'Relationship.count'] do
      post :create, params: { sop: { title: 'test_attributions', project_ids: [projects(:myexperiment_project).id] }, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop1.id]]) }
      assert_redirected_to sop_path(assigns(:sop))
    end

    # update the SOP, but supply no data about attributions - these should be removed
    assert_no_difference('Sop.count') do
      assert_difference('Relationship.count', -1) do
        put :update, params: { id: assigns(:sop).id, sop: { title: 'edited_title', project_ids: [projects(:myexperiment_project).id] }, sharing: valid_sharing, attributions: [] } # NB! no attributions supplied - should remove if any existed for the sop

        assert_redirected_to sop_path(assigns(:sop))
      end
    end
  end

  def test_attributions_will_get_destroyed_when_master_sop_is_destroyed
    # create a SOP and verify that both SOP and attributions get created
    assert_difference('Sop.count') do
      assert_difference('Relationship.count', +2) do
        post :create, params: { sop: { title: 'test_attributions', project_ids: [projects(:myexperiment_project).id] }, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop1.id], ['Sop', @sop2.id]]) }

        assert_redirected_to sop_path(assigns(:sop))
      end
    end

    # destroy the new sop and verify that the attributions get destroyed too
    sop_instance = Sop.find(assigns(:sop).id)
    assert_difference('Sop.count', -1) do
      assert_difference('Relationship.count', -2) do
        User.current_user = sop_instance.contributor
        sop_instance.destroy
      end
    end

    # double-check to see that no attributions for this sop remain
    destroyed_sop_attributions = Relationship.where subject_id: sop_instance.id,
                                                    subject_type: sop_instance.class.name,
                                                    predicate: Relationship::ATTRIBUTED_TO
    assert_equal [], destroyed_sop_attributions
  end

  def test_attributions_are_getting_properly_synchronized
    # create a SOP / attributions first
    assert_difference('Sop.count') do
      assert_difference('Relationship.count', +2) do
        post :create, params: { sop: { title: 'test_attributions', project_ids: [projects(:myexperiment_project).id] }, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop1.id], ['Sop', @sop2.id]]) }
        assert_redirected_to sop_path(assigns(:sop))
      end
    end

    # store IDs of created attribution for further checks
    sop_id = assigns(:sop).id
    sop_instance = Sop.find(sop_id)

    assert_equal 2, sop_instance.attributions.length
    attr_to_sop_one = sop_instance.attributions.where(other_object_id: @sop1.id).first
    attr_to_sop_two = sop_instance.attributions.where(other_object_id: @sop2.id).first

    # update the SOP: attributions data will add a new attribution, remove one old and keep one old unchanged -
    # this leaves the total number of attributions unchaged
    assert_no_difference ['Sop.count', 'Relationship.count'] do
      put :update, params: { id: assigns(:sop).id, sop: { title: 'edited_title' }, sharing: valid_sharing, attributions: ActiveSupport::JSON.encode([['Sop', @sop3.id], ['Sop', @sop2.id]]) }
    end
    assert_redirected_to sop_path(assigns(:sop))

    # verify it's still the same SOP
    assert_equal sop_id, assigns(:sop).id

    # --- Verify that synchronisation was performed correctly ---

    # attribution that was supposed to be deleted was really destroyed
    deleted_attr_to_sop_one = Relationship.where(subject_id: attr_to_sop_one.subject_id, subject_type: attr_to_sop_one.subject_type,
                                                 predicate: attr_to_sop_one.predicate, other_object_id: attr_to_sop_one.other_object_id,
                                                 other_object_type: attr_to_sop_one.other_object_type).first
    assert_nil deleted_attr_to_sop_one

    # attribution that was supposed to stay unchanged should preserve its ID -
    # this will then indicate that it was identified to be existing and was properly
    # handled by keeping intact instead of removing and re-creating new record with the
    # same attribution data
    remaining_attr_to_sop_two = Relationship.where(subject_id: attr_to_sop_two.subject_id, subject_type: attr_to_sop_two.subject_type,
                                                   predicate: attr_to_sop_two.predicate, other_object_id: attr_to_sop_two.other_object_id,
                                                   other_object_type: attr_to_sop_two.other_object_type).first
    assert_equal attr_to_sop_two.id, remaining_attr_to_sop_two.id

    # make sure that new attribution was created correctly
    # (we have already checked that the total number of attributions after running the test
    #  is correct - one removed, one added, one left unchanged: total - unchanged)
    new_attr = Relationship.where(subject_id: sop_id, subject_type: sop_instance.class.name,
                                  predicate: Relationship::ATTRIBUTED_TO, other_object_id: @sop3.id,
                                  other_object_type: 'Sop').first
    assert (!new_attr.nil?), "new attribution shouldn't be nil - nil means that it wasn't created"
  end

  test 'should display attributions' do
    p = FactoryBot.create :person
    login_as(p.user)
    sop1 = FactoryBot.create :sop, policy: (FactoryBot.create :public_policy), contributor: p
    sop2 = FactoryBot.create :sop, policy: (FactoryBot.create :public_policy), contributor: p
    sop3 = FactoryBot.create :sop, policy: (FactoryBot.create :public_policy), contributor: p
    Relationship.create subject: sop1, other_object: sop2, predicate: Relationship::ATTRIBUTED_TO
    sop1.reload
    sop2.reload
    assert_equal [sop2], sop1.attributions.collect(&:other_object)
    assert_equal [sop2], sop1.attributions_objects

    get :show, params: { id: sop1 }
    assert_response :success
    assert_select 'div.panel' do
      assert_select 'div.panel-heading', text: /Attributions/
      assert_select 'ul.list' do
        assert_select 'li' do
          assert_select 'a[href=?]', sop_path(sop2), text: /#{sop2.title}/
        end
      end
    end

    get :show, params: { id: sop3 }
    assert_response :success
    assert_select 'div.panel' do
      assert_select 'div.panel-heading', text: /Attributions/
      assert_select 'p.none_text', text: 'None'
    end
  end
end
