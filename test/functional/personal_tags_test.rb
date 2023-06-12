require 'test_helper'

# tests related to people and tags, split from main PeopleControllerTest
class PersonalTagsTest < ActionController::TestCase
  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'personal tags are shown' do
    p = FactoryBot.create :person
    p2 = FactoryBot.create :person
    sop = FactoryBot.create :sop, contributor: p
    cricket = FactoryBot.create :tag, annotatable: sop, source: p.user, value: 'cricket'
    frog = FactoryBot.create :tag, annotatable: sop, source: p2.user, value: 'frog'

    get :show, params: { id: p }
    assert :success

    assert_select 'div#personal_tags a[href=?]', show_ann_path(cricket.value), text: 'cricket', count: 1
    assert_select 'div#personal_tags a[href=?]', show_ann_path(frog.value), text: 'frog', count: 0
  end

  test 'expertise and tools displayed correctly' do
    p = FactoryBot.create :person
    fishing_exp = FactoryBot.create :expertise, value: 'fishing', source: p, annotatable: p
    bowling = FactoryBot.create :expertise, value: 'bowling', source: p, annotatable: p
    spade = FactoryBot.create :tool, value: 'spade', source: p, annotatable: p
    fishing_tool = FactoryBot.create :tool, value: 'fishing', source: p, annotatable: p

    get :show, params: { id: p.id }
    assert_response :success

    assert_select 'div' do
      assert_select 'p#expertise' do
        assert_select 'a[href=?]', show_ann_path(fishing_exp.value, type: 'expertise'), text: 'fishing', count: 1
        assert_select 'a[href=?]', show_ann_path(bowling.value, type: 'expertise'), text: 'bowling', count: 1
        assert_select 'a', text: 'spade', count: 0
      end
      assert_select 'p#tools' do
        assert_select 'a[href=?]', show_ann_path(spade.value, type: 'tool'), text: 'spade', count: 1
        assert_select 'a[href=?]', show_ann_path(fishing_tool.value, type: 'tool'), text: 'fishing', count: 1
        assert_select 'a', text: 'bowling', count: 0
      end
    end
  end

  test 'expertise and tools updated correctly' do
    p = people(:aaron_person)
    p.expertise = %w(one two three)
    p.tools = ['four']
    assert p.save
    assert_equal %w(one three two), p.expertise.sort
    assert_equal ['four'], p.tools.sort

    p = Person.find(p.id)
    assert_equal %w(one three two), p.expertise.sort
    assert_equal ['four'], p.tools.sort

    expertise_annotations = p.expertise.sort
    one = expertise_annotations[0]
    two = expertise_annotations[2]
    three = expertise_annotations[1]
    four = p.tools.first
    post :update, params: { id: p.id, person: { email: p.email }, expertise_list: [one, two, 'five'].join(','), tool_list: [four, 'three'].join(',') }
    assert_redirected_to p
    p = Person.find(p.id)

    assert_equal %w(five one two), p.expertise.sort
    assert_equal %w(four three), p.tools.sort
  end

  test 'expertise and tools do not appear in personal tag cloud' do
    p = FactoryBot.create :person
    login_as p.user

    exp = FactoryBot.create :expertise, source: p.user, annotatable: p, value: 'an_expertise'
    tool = FactoryBot.create :tool, source: p.user, annotatable: p, value: 'a_tool'
    tag = FactoryBot.create :tag, source: p.user, annotatable: p, value: 'a_tag'

    get :show, params: { id: p }
    assert :success

    assert_select 'div#personal_tags a[href=?]', show_ann_path(tag.value), text: 'a_tag', count: 1
    assert_select 'div#personal_tags a[href=?]', show_ann_path(tool.value), text: 'a_tool', count: 0
    assert_select 'div#personal_tags a[href=?]', show_ann_path(exp.value), text: 'an_expertise', count: 0
  end
end
