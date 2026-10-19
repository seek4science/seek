require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper


  def setup
    login_as FactoryBot.create(:user, person: FactoryBot.create(:person))
  end

  test 'handles invalid tag id' do
    id = 9999
    get :show, params: { id: id }

    assert_not_nil flash[:error]
    assert_redirected_to all_anns_path
  end

  test 'show for sample_type_tag' do
    st = FactoryBot.create(:simple_sample_type, contributor: User.current_user.person, tags: 'fish, peas')
    assert_equal 2, st.tags.count
    assert st.can_view?

    ann = st.annotations.first.value

    get :show, params: { id: ann }
    assert_response :success
    assert objects = assigns(:tagged_objects)
    assert_includes objects, st
  end

  test 'show for expertise tag' do
    p = FactoryBot.create :person
    exp = FactoryBot.create :expertise, value: 'golf', source: p.user, annotatable: p
    get :show, params: { id: exp.value }
    assert_response :success
    assert_select 'div#notice_flash', text: /1 item tagged with 'golf'/, count: 1
    assert_select 'div.list_items_container' do
      assert_select 'a[href=?]', person_path(p), text: p.name, count: 1
    end
  end

  test 'show for tools tag' do
    p = FactoryBot.create :person
    tool = FactoryBot.create :tool, value: 'spade', source: p.user, annotatable: p
    get :show, params: { id: tool.value }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'a[href=?]', person_path(p), text: p.name, count: 1
    end
  end

  test 'show for general tag' do
    df = FactoryBot.create :data_file, policy: FactoryBot.create(:public_policy)
    private_df = FactoryBot.create :data_file, policy: FactoryBot.create(:private_policy)
    tag = FactoryBot.create :tag, value: 'a tag', source: User.current_user, annotatable: df
    get :show, params: { id: tag.value }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'a', text: df.title, count: 1
      assert_select 'a', text: private_df.title, count: 0
    end
  end

  test 'index' do
    p = FactoryBot.create :person

    df = FactoryBot.create :data_file, contributor: p
    df2 = FactoryBot.create :data_file, contributor: p
    p2 = FactoryBot.create :person
    tool = FactoryBot.create :tool, value: 'fork', source: p.user, annotatable: p
    exp = FactoryBot.create :expertise, value: 'fishing', source: p.user, annotatable: p
    tag = FactoryBot.create :tag, value: 'twinkle', source: p.user, annotatable: df

    # to make sure tags only appear once
    tag2 = FactoryBot.create :tag, value: tag.value, source: p2.user, annotatable: df2

    # to make sure only tools, tags and expertise are included
    bogus = FactoryBot.create :tag, value: 'frog', source: p.user, annotatable: df, attribute_name: 'bogus'

    login_as p.user
    get :index
    assert_response :success

    assert_select 'div#super_tag_cloud a[href=?]', show_ann_path(tag.value), text: 'twinkle', count: 1
    assert_select 'div#super_tag_cloud a[href=?]', show_ann_path(tool.value), text: 'fork', count: 1
    assert_select 'div#super_tag_cloud a[href=?]', show_ann_path(exp.value), text: 'fishing', count: 1

    # this shouldn't show up because its not a tag,tool or expertise attribute
    assert_select 'div#super_tag_cloud a[href=?]', show_ann_path(bogus.value), text: 'frog', count: 0
  end

  test 'dont show duplicates for same tag for expertise and tools' do
    p = FactoryBot.create :person
    tool = FactoryBot.create :tool, value: 'xxxxx', source: p.user, annotatable: p
    exp = FactoryBot.create :expertise, value: 'xxxxx', source: p.user, annotatable: p

    login_as p.user
    get :index
    assert_response :success

    get :show, params: { id: tool.value }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'a', text: p.name, count: 1
    end
  end

  test 'can query' do
    p = FactoryBot.create :person

    df = FactoryBot.create :data_file, contributor: p
    tag = FactoryBot.create :tag, value: 'twinkle', source: p.user, annotatable: df

    get :query, params: { format: 'json', q: 'twi' }
    assert_response :success
    expected = { results: [{ id: 'twinkle', text: 'twinkle' }] }.with_indifferent_access
    assert_equal expected, JSON.parse(@response.body)

    get :query, params: { format: 'json', q: 'wink' }
    assert_response :success
    expected = { results: [{ id: 'twinkle', text: 'twinkle' }] }.with_indifferent_access
    assert_equal expected, JSON.parse(@response.body)
  end

  test 'can handle empty response from query' do
    p = FactoryBot.create :person

    df = FactoryBot.create :data_file, contributor: p
    tag = FactoryBot.create :tag, value: 'twinkle', source: p.user, annotatable: df

    get :query, params: { format: 'json', q: 'zzzxxxyyyqqq' }
    assert_response :success
    assert_empty JSON.parse(@response.body)['results']
  end
end
