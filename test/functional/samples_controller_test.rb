require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  def rest_api_test_object
    @object = Factory(:sample, policy: Factory(:public_policy))
  end

  test 'should return 406 when requesting RDF' do
    login_as(Factory(:user))
    sample = Factory :sample, contributor: User.current_user.person
    assert sample.can_view?

    get :show, params: { id: sample, format: :rdf }

    assert_response :not_acceptable
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
    get :show, params: { id: populated_patient_sample.id }
    assert_response :success
  end

  test 'new with sample type id' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    get :new, params: { sample_type_id: type.id }
    assert_response :success
    assert assigns(:sample)
    assert_equal type, assigns(:sample).sample_type
  end

  test 'create from form' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_enqueued_with(job: SampleTypeUpdateJob, args: [type, false]) do
      assert_difference('Sample.count') do
        post :create, params: { sample: { sample_type_id: type.id,
                                          data:{
                                "full name": 'Fred Smith',
                                "age": '22',
                                "weight": '22.1',
                                "postcode": 'M13 9PL'} ,
                                project_ids: [person.projects.first.id], other_creators:'frank, mary', creator_ids: [creator.id] } }
      end
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Fred Smith', sample.title
    assert_equal 'Fred Smith', sample.get_attribute_value('full name')
    assert_equal '22', sample.get_attribute_value(:age)
    assert_equal '22.1', sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
    assert_equal person, sample.contributor
    assert_equal [creator], sample.creators
    assert_equal 'frank, mary',sample.other_creators
  end

  test 'create' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_enqueued_with(job: SampleTypeUpdateJob, args: [type, false]) do
      assert_difference('Sample.count') do
        post :create, params: { sample: { sample_type_id: type.id,
                                data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                                project_ids: [person.projects.first.id], creator_ids: [creator.id] } }
      end
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Fred Smith', sample.title
    assert_equal 'Fred Smith', sample.get_attribute_value('full name')
    assert_equal '22', sample.get_attribute_value(:age)
    assert_equal '22.1', sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
    assert_equal person, sample.contributor
    assert_equal [creator], sample.creators
  end

  test 'create with validation error' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_no_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id,
                                        data: { 'full name': 'Fred Smith', age: 'Fish' },
                                        project_ids: [person.projects.first.id], creator_ids: [creator.id] } }
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Fred Smith', sample.title
    assert_equal 'Fred Smith', sample.get_attribute_value('full name')
    assert_equal 'Fish', sample.get_attribute_value(:age)

    refute sample.valid?

  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'create and update with boolean from form' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id,
                                        data: {
                              the_title: 'ttt',
                              bool: '1'} ,
                              project_ids: [person.projects.first.id] } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute_value(:the_title)
    assert sample.get_attribute_value(:bool)
    assert_no_difference('Sample.count') do
      put :update, params: { id: sample.id, sample: { data: { the_title: 'ttt', bool: '0' } } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute_value(:the_title)
    assert !sample.get_attribute_value(:bool)
  end

  test 'create with symbols' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:sample_type_with_symbols)
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id,
                                        data:{
                                            "title&": 'A',
                                            "name ++##!": 'B' ,
                                            "size range (bp)":'C'
                                        },
                                        project_ids: [person.projects.first.id] } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'A',sample.get_attribute_value('title&')
    assert_equal 'B',sample.get_attribute_value('name ++##!')
    assert_equal 'C',sample.get_attribute_value('size range (bp)')
  end

  test 'create and update with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, data: { the_title: 'ttt', bool: '1' },
                              project_ids: [person.projects.first.id] } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute_value(:the_title)
    assert sample.get_attribute_value(:bool)
    assert_no_difference('Sample.count') do
      put :update, params: { id: sample.id, sample: { data: { the_title: 'ttt', bool: '0' } } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'ttt', sample.get_attribute_value(:the_title)
    assert !sample.get_attribute_value(:bool)
  end

  test 'show sample with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = Factory(:sample, sample_type: type, contributor: person)
    sample.set_attribute_value(:the_title, 'ttt')
    sample.set_attribute_value(:bool, true)
    sample.save!
    get :show, params: { id: sample.id }
    assert_response :success
  end

  test 'edit' do
    login_as(Factory(:person))

    get :edit, params: { id: populated_patient_sample.id }

    assert_response :success
  end

  test "can't edit if extracted from a data file" do
    person = Factory(:person)
    sample = Factory(:sample_from_file, contributor: person)
    login_as(person)

    get :edit, params: { id: sample.id }

    assert_redirected_to sample_path(sample)
    assert_not_nil flash[:error]
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'update from form' do
    login_as(Factory(:person))
    creator = Factory(:person)
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_empty sample.creators

    assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample.sample_type, false]) do
      assert_no_difference('Sample.count') do
        put :update, params: {id: sample.id, sample: {
            data: {
            "full name": 'Jesus Jones',
            "age": '47',
            "postcode": 'M13 9QL'},
            creator_ids: [creator.id]}}
        assert_equal [creator], sample.creators
      end
    end

    assert assigns(:sample)
    assert_redirected_to assigns(:sample)
    updated_sample = assigns(:sample)
    updated_sample = Sample.find(updated_sample.id)
    assert_equal type_id, updated_sample.sample_type.id
    assert_equal 'Jesus Jones', updated_sample.title
    assert_equal 'Jesus Jones', updated_sample.get_attribute_value('full name')
    assert_equal '47', updated_sample.get_attribute_value(:age)
    assert_nil updated_sample.get_attribute_value(:weight)
    assert_equal 'M13 9QL', updated_sample.get_attribute_value(:postcode)
  end

  test 'update' do
    login_as(Factory(:person))
    creator = Factory(:person)
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_empty sample.creators

    assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample.sample_type, false]) do
      assert_no_difference('Sample.count') do
        put :update, params: { id: sample.id, sample: { data: { 'full name': 'Jesus Jones', age: '47', postcode: 'M13 9QL' },
                                              creator_ids: [creator.id] } }
        assert_equal [creator], sample.creators
      end
    end

    assert assigns(:sample)
    assert_redirected_to assigns(:sample)
    updated_sample = assigns(:sample)
    updated_sample = Sample.find(updated_sample.id)
    assert_equal type_id, updated_sample.sample_type.id
    assert_equal 'Jesus Jones', updated_sample.title
    assert_equal 'Jesus Jones', updated_sample.get_attribute_value('full name')
    assert_equal '47', updated_sample.get_attribute_value(:age)
    assert_nil updated_sample.get_attribute_value(:weight)
    assert_equal 'M13 9QL', updated_sample.get_attribute_value(:postcode)
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'associate with project on create from form' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                                        data: {
                                            'full name': 'Fred Smith',
                                            age: '22',
                                            weight: '22.1',
                                            postcode: 'M13 9PL'
                                        },
                                        project_ids: project_ids } }
    end
    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  test 'associate with project on create' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                              data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                              project_ids: project_ids } }
    end
    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'associate with project on update from form' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    sample = populated_patient_sample
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)

    put :update, params: { id: sample.id, sample: { title: 'Updated Sample',
                                          __sample_data_full_name: 'Jesus Jones', __sample_data_age: '47', __sample_data_postcode: 'M13 9QL' ,
                                          project_ids: project_ids } }

    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  test 'associate with project on update' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    sample = populated_patient_sample
    assert person.projects.count >= 3 # incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)

    put :update, params: { id: sample.id, sample: { title: 'Updated Sample',
                                          data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' },
                                          project_ids: project_ids } }

    assert sample = assigns(:sample)
    assert_equal person.projects[0..1].sort, sample.projects.sort
  end

  test 'contributor can view' do
    person = Factory(:person)
    login_as(person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :success
  end

  test 'non contributor cannot view' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :forbidden
  end

  test 'anonymous cannot view' do
    person = Factory(:person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :forbidden
  end

  test 'contributor can edit' do
    person = Factory(:person)
    login_as(person)

    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_response :success
  end

  test 'non contributor cannot edit' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'anonymous cannot edit' do
    person = Factory(:person)
    sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'create with sharing from form' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                                        data:{
                                            "full name": 'Fred Smith',
                                            "age": '22',
                                            "weight": '22.1',
                                            "postcode": 'M13 9PL'
                                        },
                              project_ids: [person.projects.first.id] }, policy_attributes: valid_sharing }
    end
    assert sample = assigns(:sample)
    assert_equal person, sample.contributor
    assert sample.can_view?(Factory(:person).user)
  end

  test 'create with sharing' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                              data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                              project_ids: [person.projects.first.id] }, policy_attributes: valid_sharing }
    end
    assert sample = assigns(:sample)
    assert_equal person, sample.contributor
    assert sample.can_view?(Factory(:person).user)
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'update with sharing from form' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor = person
    sample.projects = person.projects
    sample.policy = Factory(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, params: { id: sample.id, sample: { title: 'Updated Sample', __sample_data_full_name: 'Jesus Jones', __sample_data_age: '47', __sample_data_postcode: 'M13 9QL', project_ids: [] }, policy_attributes: valid_sharing }

    assert sample = assigns(:sample)
    assert sample.can_view?(other_person.user)
  end

  test 'update with sharing' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor = person
    sample.projects = person.projects
    sample.policy = Factory(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, params: { id: sample.id, sample: { title: 'Updated Sample', data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' }, project_ids: [] }, policy_attributes: valid_sharing }

    assert sample = assigns(:sample)
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

    get :index, params: { sample_type_id: sample_type1.id }
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

    get :index, params: { data_file_id: data_file.id }

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

    get :index, params: { sample_type_id: sample_type.id }

    assert_response :success

    assert_select '#samples-table tbody tr', count: 2
  end

  test 'show table with a boolean sample' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = Factory(:sample, sample_type: type, contributor: person)
    sample.set_attribute_value(:the_title, 'ttt')
    sample.set_attribute_value(:bool, true)
    sample.save!
    get :index, params: { sample_type_id: type.id }
    assert_response :success
  end

  test 'filtering for association forms' do
    person = Factory(:person)
    Factory(:sample, contributor: person, policy: Factory(:public_policy), title: 'fish')
    Factory(:sample, contributor: person, policy: Factory(:public_policy), title: 'frog')
    Factory(:sample, contributor: person, policy: Factory(:public_policy), title: 'banana')
    login_as(person.user)

    get :filter, params: { filter: '' }
    assert_select 'a', count: 3
    assert_response :success

    get :filter, params: { filter: 'f' }
    assert_select 'a', count: 2
    assert_select 'a', text: /fish/
    assert_select 'a', text: /frog/

    get :filter, params: { filter: 'fi' }
    assert_select 'a', count: 1
    assert_select 'a', text: /fish/
  end

  test 'turns strain attributes into links' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.save!

    get :show, params: { id: sample }

    assert_response :success
    assert_select 'p a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'strains show up in related items' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.save!

    get :show, params: { id: sample }

    assert_response :success
    assert_select 'div.related-items a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'cannot access when disabled' do
    person = Factory(:person)
    login_as(person.user)
    with_config_value :samples_enabled, false do
      get :show, params: { id: populated_patient_sample.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test 'destroy' do
    person = Factory(:person)
    sample = Factory(:patient_sample, contributor: person)
    type = sample.sample_type
    login_as(person.user)
    assert sample.can_delete?
    assert_enqueued_with(job: SampleTypeUpdateJob, args: [type, false]) do
      assert_difference('Sample.count', -1) do
        delete :destroy, params: { id: sample }
      end
    end
    assert_redirected_to root_path
  end

  test 'linked samples show up in related items, for both directions' do
    person = Factory(:person)
    login_as(person.user)

    sample_type = Factory(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

    sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Linking sample',
                                    patient: linked_sample.id})

    # For the sample containing the link
    get :show, params: { id: sample }

    assert_response :success
    assert_select 'div.related-items a[href=?]', sample_path(linked_sample), text: /#{linked_sample.title}/

    # For the sample being linked to
    get :show, params: { id: linked_sample }

    assert_response :success

    assert_select 'div.related-items a[href=?]', sample_path(sample), text: /#{sample.title}/
  end

  test 'related samples index link works correctly' do
    person = Factory(:person)
    login_as(person.user)

    sample_type = Factory(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

    sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Middle sample',
                                    patient: linked_sample.id})

    linking_sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Linking sample',
                                    patient: sample.id})

    with_config_value :related_items_limit, 1 do
      get :show, params: { id: sample }
    end

    assert_response :success
    assert_select 'div.related-items a[href=?]', sample_samples_path(sample), text: "View all 2 items"
  end

  test 'related samples index page works correctly' do
    person = Factory(:person)
    login_as(person.user)

    sample_type = Factory(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

    sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Middle sample',
                                    patient: linked_sample.id})

    linking_sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Linking sample',
                                    patient: sample.id})

    # For the sample containing the link
    get :index, params: { sample_id: sample }

    assert_response :success

    assert_select '.list_item_title a[href=?]', sample_path(linked_sample), text: /#{linked_sample.title}/
    assert_select '.list_item_title a[href=?]', sample_path(linking_sample), text: /#{linking_sample.title}/
  end

  test 'referring sample id is added to sample type link, if necessary' do
    person = Factory(:person)
    sample = Factory(:sample,policy:Factory(:private_policy,permissions:[Factory(:permission,contributor:person, access_type:Policy::VISIBLE)]))
    sample_type = sample.sample_type
    login_as(person.user)

    assert sample.can_view?
    refute sample_type.can_view?

    get :show, params: { id:sample.id }
    assert_response :success

    assert_select 'a[href=?]',sample_type_path(sample_type,referring_sample_id:sample.id),text:/#{sample_type.title}/

    sample2 = Factory(:sample,policy:Factory(:public_policy))
    sample_type2 = sample2.sample_type

    assert sample2.can_view?
    assert sample_type2.can_view?

    get :show, params: { id:sample2.id }
    assert_response :success

    # no referring sample required
    assert_select 'a[href=?]',sample_type_path(sample_type2),text:/#{sample_type2.title}/

  end

  test 'referring sample id is added to sample type links in list items' do
    person = Factory(:person)
    sample = Factory(:sample,policy:Factory(:private_policy,permissions:[Factory(:permission,contributor:person, access_type:Policy::VISIBLE)]))
    sample_type = sample.sample_type
    sample2 = Factory(:sample,policy:Factory(:public_policy))
    sample_type2 = sample2.sample_type
    login_as(person.user)

    assert sample.can_view?
    refute sample_type.can_view?

    assert sample2.can_view?
    assert sample_type2.can_view?

    get :index

    assert_select 'a[href=?]',sample_type_path(sample_type,referring_sample_id:sample.id),text:/#{sample_type.title}/

    # no referring sample required, ST is already visible
    assert_select 'a[href=?]',sample_type_path(sample_type2),text:/#{sample_type2.title}/

  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('sample')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    sample = Factory(:sample, contributor:person)
    login_as(person)
    assert sample.can_manage?
    get :manage, params: {id: sample}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:0

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    sample = Factory(:sample, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert sample.can_edit?
    refute sample.can_manage?
    get :manage, params: {id:sample}
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    sample = Factory(:sample, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert sample.can_manage?

    patch :manage_update, params: {id: sample,
                                   sample: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to sample

    sample.reload
    assert_equal [proj1,proj2],sample.projects.sort_by(&:id)
    assert_equal Policy::VISIBLE,sample.policy.access_type
    assert_equal 1,sample.policy.permissions.count
    assert_equal other_person,sample.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,sample.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)


    sample = Factory(:sample, projects:[proj1], policy:Factory(:private_policy,
                                                             permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute sample.can_manage?
    assert sample.can_edit?

    assert_equal [proj1],sample.projects

    patch :manage_update, params: {id: sample,
                                   sample: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    sample.reload
    assert_equal [proj1],sample.projects
    assert_equal Policy::PRIVATE,sample.policy.access_type
    assert_equal 1,sample.policy.permissions.count
    assert_equal person,sample.policy.permissions.first.contributor
    assert_equal Policy::EDITING,sample.policy.permissions.first.access_type

  end

  test 'hide manage menu for manageable but not editable items' do
    # an odd case, where you can manage but not edit, see https://jira-bsse.ethz.ch/browse/OPSK-2041
    person = Factory(:person)
    sample = Factory(:sample_from_file, contributor:person)
    login_as(person)
    assert sample.can_manage?
    assert sample.can_view?
    refute sample.can_edit?

    get :show, params:{ id:sample.id }
    assert_response :success

    assert_select 'a[href=?]',manage_sample_path(sample),text:/manage sample/i, count:0
    assert_select 'a[href=?]',edit_sample_path(sample),text:/edit sample/i, count:0
    assert_select 'a[data-method="delete"][href=?]',sample_path(sample),text:/delete sample/i, count:1

  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)

    type = Factory(:patient_sample_type)

    sample =  {sample_type_id: type.id,
               data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
               project_ids: [person.projects.first.id],
               discussion_links_attributes:[{url: "http://www.slack.com/"}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Sample.count') do
          post :create, params: {sample: sample,  policy_attributes: { access_type: Policy::VISIBLE }}
      end
    end
    sample = assigns(:sample)
    assert_equal 'http://www.slack.com/', sample.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, sample.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    asset_link = Factory(:discussion_link)
    sample = Factory(:sample, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],sample.discussion_links
    get :show, params: { id: sample }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update document with new discussion link' do
    person = Factory(:person)
    sample = Factory(:sample, contributor: person)
    login_as(person)
    assert_nil sample.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: sample.id, sample: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to sample_path(assigns(:sample))
    assert_equal 'http://www.slack.com/', sample.discussion_links.first.url
  end

  test 'batch_create' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_difference('Sample.count', 2) do
        post :batch_create, params: {data:[
        {ex_id: "1",data:{type: "samples", attributes:{attribute_map:{"full name": 'Fred Smith', "age": '22', "weight": '22.1' ,"postcode": 'M13 9PL'}},
        tags: nil,relationships:{projects:{data:[{id: person.projects.first.id, type: "projects"}]},
        sample_type:{ data:{id: type.id, type: "sample_types"}}}}},
        {ex_id: "2", data:{type: "samples",attributes:{attribute_map:{"full name": 'David Tailor', "age": '33', "weight": '33.1' ,"postcode": 'M12 8PL'}},
        tags: nil,relationships:{projects:{data:[{id: person.projects.first.id, type: "projects"}]},
        sample_type:{data:{id: type.id, type: "sample_types"}}}}}]}
    end

    sample1 = Sample.all.first
    assert_equal 'Fred Smith', sample1.title
    assert_equal 'Fred Smith', sample1.get_attribute_value('full name')
    assert_equal '22', sample1.get_attribute_value(:age)
    assert_equal '22.1', sample1.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample1.get_attribute_value(:postcode)

    sample2 = Sample.limit(2)[1]
    assert_equal 'David Tailor', sample2.title
    assert_equal 'David Tailor', sample2.get_attribute_value('full name')
    assert_equal '33', sample2.get_attribute_value(:age)
    assert_equal '33.1', sample2.get_attribute_value(:weight)
    assert_equal 'M12 8PL', sample2.get_attribute_value(:postcode)
  end

  test 'terminate batch_create if error' do
    person = Factory(:person)
    creator = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_difference('Sample.count', 0) do
        post :batch_create, params: {data:[
        {ex_id: "1",data:{type: "samples", attributes:{attribute_map:{"full name": 'Fred Smith', "age": '22', "weight": '22.1' ,"postcode": 'M13 9PL'}},
        tags: nil,relationships:{projects:{data:[{id: person.projects.first.id, type: "projects"}]},
        sample_type:{ data:{id: type.id, type: "sample_types"}}}}},
        {ex_id: "2", data:{type: "samples",attributes:{attribute_map:{"wrong attribute": 'David Tailor', "age": '33', "weight": '33.1' ,"postcode": 'M12 8PL'}},
        tags: nil,relationships:{projects:{data:[{id: person.projects.first.id, type: "projects"}]},
        sample_type:{data:{id: type.id, type: "sample_types"}}}}}]}
    end

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["errors"].length
    assert_equal "2", json_response["errors"][0]["ex_id"].to_s
  end


  test 'batch_update' do
    login_as(Factory(:person))
    creator = Factory(:person)
    sample1 = populated_patient_sample
    sample2 = populated_patient_sample
    type_id1 = sample1.sample_type.id
    type_id2 = sample2.sample_type.id
    assert_empty sample1.creators

    assert_no_difference('Sample.count') do
      put :batch_update, params: {data:[
        {id: sample1.id, data:{type: "samples", attributes:{ attribute_map:{ "full name": 'Alfred Marcus', "age": '22', "weight": '22.1' }, creator_ids: [creator.id]}}},
        {id: sample2.id, data:{type: "samples", attributes:{ attribute_map:{ "full name": 'David Tailor', "age": '33', "weight": '33.1' }, creator_ids: [creator.id]}}}]}
      assert_equal [creator], sample1.creators
    end

    samples = Sample.limit(2)

    first_updated_sample = samples[0]
    assert_equal type_id1, first_updated_sample.sample_type.id
    assert_equal 'Alfred Marcus', first_updated_sample.title
    assert_equal 'Alfred Marcus', first_updated_sample.get_attribute_value('full name')
    assert_equal '22', first_updated_sample.get_attribute_value(:age)
    assert_nil first_updated_sample.get_attribute_value(:postcode)
    assert_equal '22.1', first_updated_sample.get_attribute_value(:weight)

    last_updated_sample = samples[1]
    assert_equal type_id2, last_updated_sample.sample_type.id
    assert_equal 'David Tailor', last_updated_sample.title
    assert_equal 'David Tailor', last_updated_sample.get_attribute_value('full name')
    assert_equal '33', last_updated_sample.get_attribute_value(:age)
    assert_nil last_updated_sample.get_attribute_value(:postcode)
    assert_equal '33.1', last_updated_sample.get_attribute_value(:weight)
  end

  test 'batch_delete' do
    person = Factory(:person)
    sample1 = Factory(:patient_sample, contributor: person)
    sample2 = Factory(:patient_sample, contributor: person)
    type1 = sample1.sample_type
    type2 = sample1.sample_type
    login_as(person.user)
    assert sample1.can_delete?
    assert sample2.can_delete?
    assert_difference('Sample.count', -2) do
      delete :batch_delete, params: { data: [ {id: sample1.id}, {id: sample2.id}] }
    end
  end


  private

  def populated_patient_sample
    person = Factory(:person)
    sample = Sample.new title: 'My Sample', policy: Factory(:public_policy),
                        project_ids:person.projects.collect(&:id),contributor:person
    sample.sample_type = Factory(:patient_sample_type)
    sample.title = 'My sample'
    sample.set_attribute_value('full name', 'Fred Bloggs')
    sample.set_attribute_value(:age, 22)
    sample.save!
    sample
  end
end
