require 'test_helper'

class WorkflowClassesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'get index' do
    person = Factory(:person)
    c1, c2 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
      c2 = WorkflowClass.create!(title: 'Another Class', key: 'class1')
    end

    login_as(person)

    get :index

    assert_response :success
    assert_select 'a.btn[href=?]', edit_workflow_class_path(c1)
    assert_select 'a.btn[href=?]', edit_workflow_class_path(c2), count: 0
  end

  test 'get new' do
    person = Factory(:person)
    login_as(person)

    get :new

    assert_response :success
  end

  test 'get edit' do
    person = Factory(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    get :edit, params: { id: c1.id }

    assert_response :success
  end

  test 'create workflow class' do
    person = Factory(:person)
    login_as(person)
    p = { title: 'New Class',
          alternate_name: 'nc',
          identifier: 'https://workflow-classes.ninja/nc',
          url: 'https://workflow-classes.info/info/nc.html' }

    assert_difference('WorkflowClass.count', 1) do
      post :create, params: { workflow_class: p }
    end

    assert_redirected_to workflow_classes_path
    wc = WorkflowClass.last
    p.each do |key, value|
      assert_equal value, wc.send(key), "Expected #{key} to be #{value}"
    end
    assert_equal 'new_class', wc.key
  end


  test 'update workflow class' do
    person = Factory(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    put :update, params: { id: c1.id, workflow_class: { title: 'Wut' } }

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
  end

  test 'destroy workflow class' do
    person = Factory(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    assert_difference('WorkflowClass.count', -1) do
      delete :destroy, params: { id: c1.id }
    end

    assert_redirected_to workflow_classes_path
  end
end
