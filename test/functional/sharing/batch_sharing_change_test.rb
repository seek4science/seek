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

  test 'should have the -Bulk sharing permission change- only when you are logged in' do
    get :show, params: { id: @person }
    assert_response :success
    assert_select 'a[href=?]', batch_sharing_permission_preview_person_path, text: /Bulk sharing permission change/

    get :batch_sharing_permission_preview, params: { id: @person.id }
    assert_response :success
    assert_nil flash[:error]

    logout

    get :show, params: { id: @person }
    assert_response :success
    assert_select 'a', text: /Bulk sharing permission change/, count: 0

    get :batch_sharing_permission_preview, params: { id: @person.id }
    assert_redirected_to :root
    assert_equal flash[:error], 'You are not permitted to perform this action.'
  end


  test 'should show all the items which can change sharing permission' do

    person = User.current_user.person
    bulk_create_sharing_assets

    get :batch_sharing_permission_preview, params: { id: person.id }
    assert_response :success

    assert_select 'a[href=?]', "/people/#{person.id}", text:/#{person.name}/
    assert_select 'h1', text:/Items related to #{person.name}/
    assert_select 'div#not_isa_item', text:/Items not in ISA: /,count:1
    assert_select 'div#isa_item', text:/Items in ISA: /,count:1

    # not show "Publication"
    assert_select 'h4', text:/Publication/,count:0

    # assets in isa table
    assert_select ".in_isa", count: 6

    #assets not in isa table
    assert_select ".not_in_isa", count: 10

  end


  test 'should list the selected items' do

    params = { share_not_isa: {}, share_isa: {}}
    params= params.merge(id: @person.id)
    post :batch_change_permssion_for_selected_items, params: params
    assert_response :redirect
    assert_equal flash[:error], 'Please choose at least one resource!'

    model = Factory(:model, contributor: @person, projects: [@person.projects.first])

    params[:share_not_isa][model.class.name]||= {}
    params[:share_not_isa][model.class.name][model.id.to_s] = '1'
    df = data_with_isa
    params[:share_isa][df.class.name]||= {}
    params[:share_isa][df.class.name][df.id.to_s] = '1'

    post :batch_change_permssion_for_selected_items, params: params.merge(id: @person.id)

    assert_select '.type_and_title', count: 2 do
      assert_select 'a[href=?]', data_file_path(df)
      assert_select 'a[href=?]', model_path(model)
    end
  end

  private

  def bulk_create_sharing_assets
    authorized_types = Seek::Util.authorized_types
    authorized_types.collect do |klass|
      Factory(klass.name.underscore.to_sym, contributor: User.current_user.person)
    end
  end

  def data_file_for_sharing(owner = users(:datafile_owner))
    Factory(:data_file, contributor: owner.person)
  end

  def data_with_isa
    df = data_file_for_sharing
    other_user = users(:quentin)
    assay = Factory :experimental_assay, contributor: df.contributor,
                    study: Factory(:study, contributor: df.contributor,
                                   investigation: Factory(:investigation, contributor: df.contributor))
    other_persons_data_file = Factory(:data_file, contributor: other_user.person, policy: Factory(:policy, access_type: Policy::VISIBLE))
    assay.associate(df)
    assay.associate(other_persons_data_file)
    assert !other_persons_data_file.can_manage?
    df
  end

end
