require 'test_helper'

# tests specific to swapping partials using ActionView::Renderer.define_alternative with :seek_partial
class RenderPartialFlippingTest < ActionController::TestCase
  tests :people

  test 'default' do
    person = Factory(:person)
    project = person.projects.first
    inst = person.institutions.first

    refute_nil project
    refute_nil inst

    get :show, id: person.id
    assert_response :success

    # check the test partial isn't show
    assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 0

    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', project_path(project), text: project.title
          assert_select 'a[href=?]', institution_path(inst), text: inst.title
        end
      end
    end
  end

  test 'alternative is empty text using strings' do
    person = Factory(:person)
    with_alternative_rendering({ controller: 'people', seek_partial: 'general/items_related_to' }, '') do
      get :show, id: person.id
      assert_response :success

      assert_select 'h2', text: /Related items/i, count: 0
      assert_select 'div.list_items_container', count: 0
    end
  end

  test 'alternative is empty text using symb' do
    person = Factory(:person)
    with_alternative_rendering({ controller: :people, seek_partial: 'general/items_related_to'.to_sym }, '') do
      get :show, id: person.id
      assert_response :success

      assert_select 'h2', text: /Related items/i, count: 0
      assert_select 'div.list_items_container', count: 0
    end
  end

  test 'alternative is empty text mixed' do
    person = Factory(:person)
    with_alternative_rendering({ controller: :people, seek_partial: 'general/items_related_to' }, '') do
      get :show, id: person.id
      assert_response :success

      assert_select 'h2', text: /Related items/i, count: 0
      assert_select 'div.list_items_container', count: 0
    end
  end

  test 'alternative is empty text mixed2' do
    person = Factory(:person)
    with_alternative_rendering({ controller: :people, seek_partial: 'general/items_related_to' }, '') do
      get :show, id: person.id
      assert_response :success

      assert_select 'h2', text: /Related items/i, count: 0
      assert_select 'div.list_items_container', count: 0
    end
  end

  test 'alternative is empty text no controller' do
    person = Factory(:person)
    with_alternative_rendering({ seek_partial: 'general/items_related_to' }, '') do
      get :show, id: person.id
      assert_response :success

      assert_select 'h2', text: /Related items/i, count: 0
      assert_select 'div.list_items_container', count: 0
    end
  end

  test 'alternative test partial usign strings' do
    person = Factory(:person)
    with_alternative_rendering({ controller: 'people', seek_partial: 'general/items_related_to' }, 'general/test_partial') do
      get :show, id: person.id
      assert_response :success
      assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 1
    end
  end

  test 'alternative test partial usign symbols' do
    person = Factory(:person)
    with_alternative_rendering({ controller: :people, seek_partial: 'general/items_related_to'.to_sym }, 'general/test_partial') do
      get :show, id: person.id
      assert_response :success
      assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 1
    end
  end

  test 'alternative test partial mixed' do
    person = Factory(:person)
    with_alternative_rendering({ controller: :people, seek_partial: 'general/items_related_to' }, 'general/test_partial') do
      get :show, id: person.id
      assert_response :success
      assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 1
    end
  end

  test 'alternative test partial mixed2' do
    person = Factory(:person)
    with_alternative_rendering({ controller: 'people', seek_partial: 'general/items_related_to'.to_sym }, 'general/test_partial') do
      get :show, id: person.id
      assert_response :success
      assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 1
    end
  end

  test 'alternative test partial controller match takes precendence' do
    person = Factory(:person)
    with_alternative_rendering({ seek_partial: 'general/items_related_to' }, '') do
      with_alternative_rendering({ controller: 'people', seek_partial: 'general/items_related_to' }, 'general/test_partial') do
        get :show, id: person.id
        assert_response :success
        assert_select 'p', text: /This is a partial for purely testing purposes/i, count: 1
      end
    end
  end
end
