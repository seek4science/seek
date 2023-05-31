require 'test_helper'

class WorkflowClassesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'get index' do
    person = FactoryBot.create(:person)
    core_type, user_added_1, user_added_2, user_added_3 = nil
    disable_authorization_checks do
      core_type = FactoryBot.create(:cwl_workflow_class)
      user_added_1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
      user_added_2 = WorkflowClass.create!(title: 'Another Class', key: 'class1')
      user_added_3 = WorkflowClass.create!(title: 'Class with Logo', key: 'has-logo',
                                           logo_image: fixture_file_upload('file_picture.png', 'image/png'))
    end

    login_as(person)

    get :index

    assert_response :success
    assert_select 'a.btn[href=?]', edit_workflow_class_path(core_type), count: 0
    assert_select 'a.btn[href=?]', edit_workflow_class_path(user_added_1)
    assert_select 'a.btn[href=?]', edit_workflow_class_path(user_added_2), count: 0
    assert_select 'a.btn[href=?]', edit_workflow_class_path(user_added_3), count: 0

    # Check avatars
    assert_select 'img.workflow-class-logo-sm', count: 4
    assert_select 'img.workflow-class-logo-sm[src=?]', '/assets/avatars/workflow_types/avatar-cwl.svg', count: 1
    assert_select 'img.workflow-class-logo-sm[src=?]', '/assets/avatars/avatar-workflow.png', count: 2
    assert_select 'img.workflow-class-logo-sm[src=?]',
                  workflow_class_avatar_path(user_added_3, user_added_3.avatar, size: '32x32'), count: 1
  end

  test 'admin can edit any workflow class' do
    person = FactoryBot.create(:person)
    core_type, c1, c2 = nil
    disable_authorization_checks do
      core_type = FactoryBot.create(:cwl_workflow_class)
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
      c2 = WorkflowClass.create!(title: 'Another Class', key: 'class1')
    end

    login_as(FactoryBot.create(:admin))

    get :index

    assert_response :success
    assert_select 'a.btn[href=?]', edit_workflow_class_path(core_type)
    assert_select 'a.btn[href=?]', edit_workflow_class_path(c1)
    assert_select 'a.btn[href=?]', edit_workflow_class_path(c2)
  end

  test 'get new' do
    person = FactoryBot.create(:person)
    login_as(person)

    get :new

    assert_response :success
  end

  test 'get edit' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    get :edit, params: { id: c1.id }

    assert_response :success
  end

  test 'create workflow class' do
    person = FactoryBot.create(:person)
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
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    put :update, params: { id: c1.id, workflow_class: { title: 'Wut' } }

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
  end

  test 'update workflow class as admin' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(FactoryBot.create(:admin))

    put :update, params: { id: c1.id, workflow_class: { title: 'Wut' } }

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
  end

  test 'destroy workflow class' do
    person = FactoryBot.create(:person)
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

  test 'cannot create workflow class if not registered' do
    person = FactoryBot.create(:person)
    logout
    p = { title: 'New Class',
          alternate_name: 'nc',
          identifier: 'https://workflow-classes.ninja/nc',
          url: 'https://workflow-classes.info/info/nc.html' }

    assert_no_difference('WorkflowClass.count') do
      post :create, params: { workflow_class: p }
    end

    assert flash[:error].include?('create')
    assert_redirected_to workflow_classes_path
  end

  test 'cannot update workflow class if not contributor/admin' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(FactoryBot.create(:person))

    put :update, params: { id: c1.id, workflow_class: { title: 'Wut' } }

    assert flash[:error].include?('not authorized to edit')
    assert_redirected_to workflow_classes_path
    refute_equal 'Wut', c1.reload.title
  end

  test 'cannot destroy workflow class if not contributor/admin' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(FactoryBot.create(:person))

    assert_no_difference('WorkflowClass.count') do
      delete :destroy, params: { id: c1.id }
    end

    assert flash[:error].include?('not authorized to delete')
    assert_redirected_to workflow_classes_path
  end

  test 'create workflow class with an avatar' do
    person = FactoryBot.create(:person)
    login_as(person)
    p = { title: 'New Class',
          alternate_name: 'nc',
          identifier: 'https://workflow-classes.ninja/nc',
          url: 'https://workflow-classes.info/info/nc.html',
          logo_image: fixture_file_upload('file_picture.png', 'image/png')
    }

    assert_difference('Avatar.count', 1) do
      assert_difference('WorkflowClass.count', 1) do
        post :create, params: { workflow_class: p }
      end
    end

    assert_redirected_to workflow_classes_path
    wc = WorkflowClass.last
    assert wc.avatar
    assert wc.defines_own_avatar?
  end

  test 'update workflow class with an logo' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person)
    end
    login_as(person)

    refute c1.avatar
    refute c1.defines_own_avatar?

    assert_difference('Avatar.count', 1) do
      put :update, params: {
        id: c1.id,
        workflow_class: {
          title: 'Wut',
          logo_image: fixture_file_upload('file_picture.png', 'image/png')
        }
      }
    end

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
    assert c1.avatar
    assert c1.defines_own_avatar?
  end

  test 'updating workflow class does not remove logo' do
    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person,
                                 logo_image: fixture_file_upload('file_picture.png', 'image/png'))
    end
    login_as(person)

    avatar = c1.avatar
    assert avatar
    assert c1.defines_own_avatar?

    assert_no_difference('Avatar.count') do
      put :update, params: {
        id: c1.id,
        workflow_class: {
          title: 'Wut'
        }
      }
    end

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
    assert_equal avatar, c1.avatar
  end

  test 'updating workflow class logo removes the old one' do
    FactoryBot.create(:user_added_workflow_class_with_logo)
    FactoryBot.create(:user_added_workflow_class_with_logo)

    person = FactoryBot.create(:person)
    c1 = nil
    disable_authorization_checks do
      c1 = WorkflowClass.create!(title: 'My Class', key: 'mine', contributor: person,
                                 logo_image: fixture_file_upload('file_picture.png', 'image/png'))
    end
    login_as(person)

    old_avatar = c1.avatar
    old_avatar_id = old_avatar.id
    assert old_avatar
    assert c1.defines_own_avatar?

    assert_no_difference('Avatar.count') do # 1 removed, 1 added
      put :update, params: {
        id: c1.id,
        workflow_class: {
          title: 'Wut',
          logo_image: fixture_file_upload('file_picture.png', 'image/png')
        }
      }
    end

    assert_redirected_to workflow_classes_path
    assert_equal 'Wut', c1.reload.title
    assert_not_equal old_avatar_id, c1.avatar_id
    assert_not_equal old_avatar, c1.avatar
    assert_nil Avatar.find_by_id(old_avatar_id)
  end
end
