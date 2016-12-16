require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include HtmlHelper

  def setup
    Factory(:person)#to prevent person being first person and therefore admin
  end

  test 'index' do
    Factory(:sample, policy: Factory(:public_policy))
    get :index
    assert_response :success
    assert_select '#samples-table table', count: 0
  end

  test 'new without sample type id' do
    login_as(Factory(:person))
    get :new
    assert_redirected_to select_sample_types_path
  end

  test 'show' do
    get :show, id: populated_patient_sample.id
    assert_response :success
  end

  test 'new with sample type id' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    get :new, sample_type_id: type.id
    assert_response :success
    assert assigns(:sample)
    assert_equal type, assigns(:sample).sample_type
  end

  test 'create' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id,
                              data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                              project_ids: [person.projects.first.id] },
           :creators=>[[creator.name,creator.id]].to_json
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'George Osborne', sample.title
    assert_equal 'George Osborne', sample.get_attribute(:full_name)
    assert_equal '22', sample.get_attribute(:age)
    assert_equal '22.1', sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)
    assert_equal person.user, sample.contributor
    assert_equal [creator],sample.creators

    #job should have been triggered
    assert SampleTypeUpdateJob.new(type,false).exists?
  end

  test 'create and update with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, data: { the_title: 'ttt', bool: '1' },
                              project_ids: [person.projects.first.id] }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute(:the_title)
    assert sample.get_attribute(:bool)
    assert_no_difference('Sample.count') do
      put :update, id: sample.id, sample: { data: { the_title: 'ttt', bool: '0' } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute(:the_title)
    assert !sample.get_attribute(:bool)
  end

  test 'show sample with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = Factory(:sample, sample_type: type)
    sample.set_attribute(:the_title, 'ttt')
    sample.set_attribute(:bool, true)
    sample.save!
    get :show, id: sample.id
    assert_response :success
  end

  test 'edit' do
    login_as(Factory(:person))

    get :edit, id: populated_patient_sample.id

    assert_response :success
  end

  test "can't edit if extracted from a data file" do
    person = Factory(:person)
    sample = Factory(:sample_from_file, contributor: person)
    login_as(person)

    get :edit, id: sample.id

    assert_redirected_to sample_path(sample)
    assert_not_nil flash[:error]
  end

  test 'update' do
    login_as(Factory(:person))
    creator = Factory(:person)
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_empty sample.creators

    assert_no_difference('Sample.count') do
      put :update, id: sample.id, sample: { data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' } },
          :creators=>[[creator.name,creator.id]].to_json
      assert_equal [creator],sample.creators
    end

    assert assigns(:sample)
    assert_redirected_to assigns(:sample)
    updated_sample = assigns(:sample)
    updated_sample = Sample.find(updated_sample.id)
    assert_equal type_id, updated_sample.sample_type.id
    assert_equal 'Jesus Jones', updated_sample.title
    assert_equal 'Jesus Jones', updated_sample.get_attribute(:full_name)
    assert_equal '47', updated_sample.get_attribute(:age)
    assert_nil updated_sample.get_attribute(:weight)
    assert_equal 'M13 9QL', updated_sample.get_attribute(:postcode)
    #job should have been triggered
    assert SampleTypeUpdateJob.new(sample.sample_type,false).exists?
  end

  test 'associate with project on create' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample',
                              data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                              project_ids: project_ids }
    end
    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  test 'associate with project on update' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    sample = populated_patient_sample
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)

    put :update, id: sample.id, sample: { title: 'Updated Sample',
                                          data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' },
                                          project_ids: project_ids }

    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  test 'contributor can view' do
    person = Factory(:person)
    login_as(person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, id: sample.id
    assert_response :success
  end

  test 'non contributor cannot view' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, id: sample.id
    assert_response :forbidden
  end

  test 'anonymous cannot view' do
    person = Factory(:person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, id: sample.id
    assert_response :forbidden
  end

  test 'contributor can edit' do
    person = Factory(:person)
    login_as(person)

    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, id: sample.id
    assert_response :success
  end

  test 'non contributor cannot edit' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, id: sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'anonymous cannot edit' do
    person = Factory(:person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, id: sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'create with sharing' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)

    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample',
                              data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                              project_ids: [person.projects.first.id] }, sharing: valid_sharing
    end
    assert sample = assigns(:sample)
    assert_equal person.user, sample.contributor
    assert_equal Policy::ALL_USERS, sample.policy.sharing_scope
    assert sample.can_view?(Factory(:person).user)
  end

  test 'update with sharing' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor = person
    sample.policy = Factory(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, id: sample.id, sample: { title: 'Updated Sample',  data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' }, project_ids: [] }, sharing: valid_sharing

    assert sample = assigns(:sample)
    assert_equal Policy::ALL_USERS, sample.policy.sharing_scope
    assert sample.can_view?(other_person.user)
  end

  test 'filter by sample_type route' do
    assert_routing 'sample_types/7/samples', controller: 'samples', action: 'index', sample_type_id: '7'
  end

  test 'filter by sample type' do
    sample_type1 = Factory(:simple_sample_type)
    sample_type2 = Factory(:simple_sample_type)
    sample1 = Factory(:sample, sample_type: sample_type1, policy: Factory(:public_policy), title: 'SAMPLE 1')
    sample2 = Factory(:sample, sample_type: sample_type2, policy: Factory(:public_policy), title: 'SAMPLE 2')

    get :index, sample_type_id: sample_type1.id
    assert_response :success
    assert samples = assigns(:samples)
    assert_includes samples, sample1
    refute_includes samples, sample2
  end

  test 'should get table view for data file' do
    data_file = Factory(:data_file, policy: Factory(:private_policy))
    sample_type = Factory(:simple_sample_type)
    3.times do # public
      Factory(:sample, sample_type: sample_type, contributor: data_file.contributor, policy: Factory(:private_policy),
                       originating_data_file: data_file)
    end

    login_as(data_file.contributor)

    get :index, data_file_id: data_file.id

    assert_response :success
    # Empty table - content is loaded asynchronously (see data_files_controller_test.rb)
    assert_select '#samples-table tbody tr', count: 0
    assert_select '#samples-table thead th', count: 3
  end

  test 'should get table view for sample type' do
    person = Factory(:person)
    sample_type = Factory(:simple_sample_type)
    2.times do # public
      Factory(:sample, sample_type: sample_type, contributor: person, policy: Factory(:private_policy))
    end
    3.times do # private
      Factory(:sample, sample_type: sample_type, policy: Factory(:private_policy))
    end

    login_as(person.user)

    get :index, sample_type_id: sample_type.id

    assert_response :success

    assert_select '#samples-table tbody tr', count: 2
  end

  test 'show table with a boolean sample' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = Factory(:sample, sample_type: type)
    sample.set_attribute(:the_title, 'ttt')
    sample.set_attribute(:bool, true)
    sample.save!
    get :index, sample_type_id: type.id
    assert_response :success
  end

  test 'filtering for association forms' do
    person = Factory(:person)
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: 'fish')
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: 'frog')
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: 'banana')
    login_as(person.user)

    get :filter, filter: ''
    assert_select 'a', count: 3
    assert_response :success

    get :filter, filter: 'f'
    assert_select 'a', count: 2
    assert_select 'a', text: /fish/
    assert_select 'a', text: /frog/

    get :filter, filter: 'fi'
    assert_select 'a', count: 1
    assert_select 'a', text: /fish/
  end

  test 'turns strain attributes into links' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.save!

    get :show, id: sample

    assert_response :success
    assert_select 'p a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'strains show up in related items' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.save!

    get :show, id: sample

    assert_response :success
    assert_select 'div.related-items a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'cannot access when disabled' do
    person = Factory(:person)
    login_as(person.user)
    with_config_value :samples_enabled,false do

      get :show, id: populated_patient_sample.id
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error]=nil

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error]=nil

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]

    end

  end

  test 'destroy' do
    person=Factory(:person)
    sample = Factory(:patient_sample,contributor:person)
    type = sample.sample_type
    login_as(person.user)
    assert sample.can_delete?
    assert_difference("Sample.count",-1) do
      delete :destroy, id: sample
    end
    assert_redirected_to root_path
    #job should have been triggered
    assert SampleTypeUpdateJob.new(type,false).exists?
  end

  private

  def populated_patient_sample
    sample = Sample.new title: 'My Sample', policy: Factory(:public_policy), contributor: Factory(:person),
                        project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    sample.title = 'My sample'
    sample.set_attribute(:full_name, 'Fred Bloggs')
    sample.set_attribute(:age, 22)
    sample.save!
    sample
  end
end
