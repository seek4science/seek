require 'test_helper'

class SopsAnnotationTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases


  tests SopsController

  test 'update tags with ajax only applied when viewable' do
    p = FactoryBot.create :person
    p2 = FactoryBot.create :person
    viewable_sop = FactoryBot.create :sop, contributor: p2, policy: FactoryBot.create(:publicly_viewable_policy)
    dummy_sop = FactoryBot.create :sop

    login_as p.user

    assert viewable_sop.can_view?(p.user)
    assert !viewable_sop.can_edit?(p.user)

    golf = FactoryBot.create :tag, annotatable: dummy_sop, source: p2, value: 'golf'

    post :update_annotations_ajax, xhr: true, params: { id: viewable_sop, tag_list: golf.value.text }

    viewable_sop.reload

    assert_equal ['golf'], viewable_sop.annotations.collect { |a| a.value.text }

    private_sop = FactoryBot.create :sop, contributor: p2, policy: FactoryBot.create(:private_policy)

    assert !private_sop.can_view?(p.user)
    assert !private_sop.can_edit?(p.user)

    post :update_annotations_ajax, xhr: true, params: { id: private_sop, tag_list: golf.value.text }

    private_sop.reload
    assert private_sop.annotations.empty?
  end

  test 'update tags with ajax' do
    p = FactoryBot.create :person

    login_as p.user

    p2 = FactoryBot.create :person
    sop = FactoryBot.create :sop, contributor: p

    assert sop.annotations.empty?, 'this sop should have no tags for the test'

    golf = FactoryBot.create :tag, annotatable: sop, source: p2.user, value: 'golf'
    FactoryBot.create :tag, annotatable: sop, source: p2.user, value: 'sparrow'

    sop.reload

    assert_equal %w(golf sparrow), sop.annotations.collect { |a| a.value.text }.sort
    assert_equal [], sop.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    post :update_annotations_ajax, xhr: true, params: { id: sop, tag_list: "soup,#{golf.value.text}" }

    sop.reload

    assert_equal %w(golf soup sparrow), sop.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w(golf soup), sop.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'should update sop tags' do
    p = FactoryBot.create :person
    sop = FactoryBot.create :sop, contributor: p
    dummy_sop = FactoryBot.create :sop

    login_as p.user
    assert sop.annotations.empty?, 'Should have no annotations'
    FactoryBot.create :tag, source: p.user, annotatable: sop, value: 'fish'
    FactoryBot.create :tag, source: p.user, annotatable: sop, value: 'apple'
    golf = FactoryBot.create :tag, source: p.user, annotatable: dummy_sop, value: 'golf'

    sop.reload
    assert_equal %w(apple fish), sop.annotations.collect { |a| a.value.text }.sort

    put :update, params: { id: sop, tag_list: "soup,#{golf.value.text}", sop: { title: sop.title }, sharing: valid_sharing }
    sop.reload

    assert_equal %w(golf soup), sop.annotations.collect { |a| a.value.text }.sort
  end

  test 'should update sop tags with correct ownership' do
    p1 = FactoryBot.create :person
    p2 = FactoryBot.create :person
    p3 = FactoryBot.create :person

    sop = FactoryBot.create :sop, contributor: p1

    assert sop.annotations.empty?, 'This sop should have no tags'

    login_as p1.user

    FactoryBot.create :tag, source: p1.user, annotatable: sop, value: 'fish'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'fish'
    golf = FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'golf'
    FactoryBot.create :tag, source: p3.user, annotatable: sop, value: 'apple'

    sop.reload

    assert_equal ['fish'], sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }
    assert_equal %w(fish golf), sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
    assert_equal ['apple'], sop.annotations.select { |a| a.source == p3.user }.collect { |a| a.value.text }
    assert_equal %w(apple fish golf), sop.annotations.collect { |a| a.value.text }.uniq.sort

    put :update, params: { id: sop, tag_list: "soup,#{golf.value.text}", sop: { title: sop.title }, sharing: valid_sharing }
    sop.reload

    assert_equal ['soup'], sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }
    assert_equal ['golf'], sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
    assert_equal [], sop.annotations.select { |a| a.source == p3.user }.collect { |a| a.value.text }
    assert_equal %w(golf soup), sop.annotations.collect { |a| a.value.text }.uniq.sort
  end

  test 'should update sop tags with correct ownership2' do
    # a specific case where a tag to keep was added by both the owner and another user.
    # Test checks that the correct tag ownership is preserved.

    p1 = FactoryBot.create :person
    p2 = FactoryBot.create :person

    sop = FactoryBot.create :sop, contributor: p1

    assert sop.annotations.empty?, 'This sop should have no tags'

    login_as p1.user

    FactoryBot.create :tag, source: p1.user, annotatable: sop, value: 'fish'
    golf = FactoryBot.create :tag, source: p1.user, annotatable: sop, value: 'golf'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'apple'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'golf'

    sop.reload

    assert_equal %w(fish golf), sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }.sort
    assert_equal %w(apple golf), sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    put :update, params: { id: sop, tag_list: golf.value.text, sop: { title: sop.title }, sharing: valid_sharing }
    sop.reload

    assert_equal ['golf'], sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }.sort
    assert_equal ['golf'], sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'update tags with known tags passed as unrecognised' do
    # checks that when a known tag is incorrectly passed as a new tag, it is correctly handled
    # this can happen when a tag is typed in full, rather than relying on autocomplete, and can affect the correct preservation of ownership

    p1 = FactoryBot.create :person
    p2 = FactoryBot.create :person

    sop = FactoryBot.create :sop, contributor: p1

    assert sop.annotations.empty?, 'This sop should have no tags'

    login_as p1.user

    fish = FactoryBot.create :tag, source: p1.user, annotatable: sop, value: 'fish'
    golf = FactoryBot.create :tag, source: p1.user, annotatable: sop, value: 'golf'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'fish'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: 'soup'

    sop.reload

    assert_equal %w(fish golf), sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }.sort
    assert_equal %w(fish soup), sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    put :update, params: { id: sop, tag_list: "fish,#{golf.value.text}", sop: { title: sop.title }, sharing: valid_sharing }

    sop.reload

    assert_equal %w(fish golf), sop.annotations.select { |a| a.source == p1.user }.collect { |a| a.value.text }.sort
    assert_equal ['fish'], sop.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'create sop with tags' do
    p = FactoryBot.create :person
    login_as p.user

    another_sop = FactoryBot.create :sop, contributor: p
    golf = FactoryBot.create :tag, source: p.user, annotatable: another_sop, value: 'golf'

    sop = { title: 'Test', project_ids: [p.projects.first.id] }
    blob = { data: file_for_upload }

    assert_difference('Sop.count') do
      put :create, params: { sop: sop, content_blobs: [blob], sharing: valid_sharing, tag_list: "fish,#{golf.value.text}" }
    end

    assert_redirected_to sop_path(assigns(:sop))
    sop = assigns(:sop)
    assert_equal %w(fish golf), sop.annotations_as_text_array.sort
  end

  test 'tag cloud shown on show page' do
    p = FactoryBot.create :person
    login_as p.user
    sop = FactoryBot.create :sop, contributor: p

    get :show, params: { id: sop }
    assert_response :success

    assert_select 'div#tags_box' do
      assert_select 'a', text: /Add your tags/, count: 1
      assert_select 'a', text: /Update your tags/, count: 0
    end

    assert_select 'div#tag_cloud' do
      assert_select 'p', text: /not yet been tagged/, count: 1
    end

    sop.annotate_with %w(fish sparrow sprocket)
    sop.save!

    get :show, params: { id: sop }
    assert_response :success

    assert_select 'div#tags_box' do
      assert_select 'a', text: /Add your tags/, count: 0
      assert_select 'a', text: /Update your tags/, count: 1
    end

    assert_select 'div#tag_cloud' do
      assert_select 'a', text: 'fish', count: 1
      assert_select 'a', text: 'sparrow', count: 1
      assert_select 'a', text: 'sprocket', count: 1
    end
  end

  test "asset tag cloud shouldn't duplicate tags for different owners" do
    p = FactoryBot.create :person
    p2 = FactoryBot.create :person
    login_as p.user
    sop = FactoryBot.create :sop, contributor: p

    coffee = FactoryBot.create :tag, source: p.user, annotatable: sop, value: 'coffee'
    FactoryBot.create :tag, source: p2.user, annotatable: sop, value: coffee.value

    get :show, params: { id: sop }
    assert_response :success

    assert_select 'div#tag_cloud' do
      assert_select 'a', text: /coffee/, count: 1
    end
  end

  test 'form includes tag section' do
    p = FactoryBot.create :person
    login_as p.user
    get :new
    assert_response :success
    assert_select 'select#tag_list'

    sop = FactoryBot.create :sop, contributor: p
    get :edit, params: { id: sop }
    assert_response :success
    assert_select 'select#tag_list'
  end
end
