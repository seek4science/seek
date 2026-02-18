require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases
  include RdfTestCases

  def rdf_test_object
    FactoryBot.create(:max_sample, policy: FactoryBot.create(:public_policy))
  end

  test 'index' do
    FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
    get :index
    assert_response :success
    assert_select 'div.index-filters'
    assert_select 'div.index-content' do
      assert_select 'div.list_item', count: 1
    end
  end

  test 'new without sample type id' do
    login_as(FactoryBot.create(:person))
    get :new
    assert_redirected_to select_sample_types_path(act: :create)
  end

  test 'show' do
    get :show, params: { id: populated_patient_sample.id }
    assert_response :success
  end

  test 'new with sample type id' do
    login_as(FactoryBot.create(:person))
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
    get :new, params: { sample_type_id: type.id }
    assert_response :success
    assert assigns(:sample)
    assert_equal type, assigns(:sample).sample_type

    # displays description if set
    assert_select 'div label+p', text:/the weight of the patient/i, count:1
  end

  test 'cannot access new with hidden sample type' do
    login_as(FactoryBot.create(:person))
    hidden_type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:private_policy), contributor: FactoryBot.create(:person))
    refute hidden_type.can_view?
    get :new, params: { sample_type_id: hidden_type.id }

    assert_redirected_to root_path
    assert_equal 'You are not authorized to use this Sample type', flash[:error]
  end

  test 'create from form' do
    person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
    assert_enqueued_with(job: SampleTypeUpdateJob, args: [type, false]) do
      assert_difference('Sample.count') do
        post :create, params: { sample: { sample_type_id: type.id,
                                          data: {
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
    assert_equal 22, sample.get_attribute_value(:age)
    assert_equal 22.1, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
    assert_equal person, sample.contributor
    assert_equal [creator], sample.creators
    assert_equal 'frank, mary',sample.other_creators
  end

  test 'cannot create with hidden sample type' do
    person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(person)
    hidden_type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:private_policy), contributor: FactoryBot.create(:person))
    refute hidden_type.can_view?
    assert_no_enqueued_jobs do
      assert_no_difference('Sample.count') do
        post :create, params: { sample: { sample_type_id: hidden_type.id,
                                          data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                                          project_ids: [person.projects.first.id], creator_ids: [creator.id] } }
      end
    end
    assert_redirected_to root_path
    assert_equal 'You are not authorized to use this Sample type', flash[:error]
  end

  test 'create' do
    person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
    obs_unit = FactoryBot.create(:observation_unit, contributor: person)
    assert_enqueued_with(job: SampleTypeUpdateJob, args: [type, false]) do
      assert_difference('Sample.count') do
        post :create, params: { sample: { sample_type_id: type.id,
                                          data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                                          project_ids: [person.projects.first.id], creator_ids: [creator.id],
                                          observation_unit_id: obs_unit.id } }
      end
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Fred Smith', sample.title
    assert_equal 'Fred Smith', sample.get_attribute_value('full name')
    assert_equal 22, sample.get_attribute_value(:age)
    assert_equal 22.1, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
    assert_equal person, sample.contributor
    assert_equal [creator], sample.creators
    assert_equal obs_unit, sample.observation_unit
  end

  test 'create with validation error' do
    person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
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
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:sample_attribute, title: 'bool',
                      sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: false, sample_type: type)
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
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:sample_type_with_symbols, policy: FactoryBot.create(:public_policy))
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id,
                                        data: {
                                            "title&": 'A',
                                            "name ++##!": 'B' ,
                                            "size range (bp)": 'C'
                                        },
                                        project_ids: [person.projects.first.id] } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal 'A',sample.get_attribute_value('title&')
    assert_equal 'B',sample.get_attribute_value('name ++##!')
    assert_equal 'C',sample.get_attribute_value('size range (bp)')
  end

  test 'create and update with boolean' do
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:sample_attribute, title: 'bool',
                      sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: false, sample_type: type)
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

  test 'create and update with cv list' do
    person = FactoryBot.create(:person)
    login_as(person)

    type = FactoryBot.create(:apples_list_controlled_vocab_sample_type, policy: FactoryBot.create(:public_policy))
    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id,
                                        data: { apples: ['Granny Smith', 'Bramley'] },
                                        project_ids: [person.projects.first.id] } }
    end
    assert_not_nil sample = assigns(:sample)
    assert_equal ['Granny Smith', 'Bramley'], sample.get_attribute_value(:apples)

    # cv list type data must be an array
    assert_no_difference('Sample.count') do
      put :update, params: { id: sample.id, sample: { data: { apples: 'Granny Smith' } } }
    end

    # the required attribute must be filled in
    assert_no_difference('Sample.count') do
      put :update, params: { id: sample.id, sample: { data: { apples: nil } } }
    end

  end

  test 'show sample with boolean' do
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:simple_sample_type)
    FactoryBot.create(:sample_attribute, title: 'bool',
                      sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = FactoryBot.create(:sample, sample_type: type, contributor: person)
    sample.set_attribute_value(:the_title, 'ttt')
    sample.set_attribute_value(:bool, true)
    sample.save!
    get :show, params: { id: sample.id }
    assert_response :success
  end

  test 'edit' do
    person = FactoryBot.create(:person)
    login_as(person)
    FactoryBot.create(:observation_unit, contributor: person)

    get :edit, params: { id: populated_patient_sample.id }

    assert_response :success
    assert_nil flash[:error]
  end

  test "warn on first edit if extracted from a data file" do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample_from_file, contributor: person)
    login_as(person)

    get :edit, params: { id: sample.id }
    assert_response :success
    assert_not_nil flash[:error]
  end

  test "source data datafile taged as invalid after edit" do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample_from_file, contributor: person)
    login_as(person)

    put :update, params: { id: sample.id, sample: { data: { "name": "Modified Sample" } } }
    sample.reload
    assert_equal "Modified Sample", sample.title
    assert sample.edit_count.positive?

    get :show, params: { id: sample.id }
    assert_response :success
    assert_select 'span.label-danger', text: /No longer valid/, count: 1
  end

  test "no longer warn if sample extracted from a data file has already been edited" do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample_from_file, contributor: person)
    login_as(person)

    put :update, params: { id: sample.id, sample: { data: { "name": "Modified Sample" } } }
    sample.reload
    assert_equal "Modified Sample", sample.title
    assert sample.edit_count.positive?

    get :edit, params: { id: sample.id }
    assert_response :success
    assert_nil flash[:error]
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'update from form' do
    person = FactoryBot.create(:person)
    login_as(person)
    creator = FactoryBot.create(:person)
    sample = populated_patient_sample
    type_id = sample.sample_type.id
    obs_unit = FactoryBot.create(:observation_unit, contributor: person)

    assert_empty sample.creators

    assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample.sample_type, false]) do
      assert_no_difference('Sample.count') do
        put :update, params: {id: sample.id, sample: {
            data: {
            "full name": 'Jesus Jones',
            "age": '47',
            "postcode": 'M13 9QL'},
            creator_ids: [creator.id],
            observation_unit_id: obs_unit.id }}
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
    assert_equal 47, updated_sample.get_attribute_value(:age)
    assert_nil updated_sample.get_attribute_value(:weight)
    assert_equal 'M13 9QL', updated_sample.get_attribute_value(:postcode)
    assert_equal obs_unit, updated_sample.observation_unit
  end

  test 'update' do
    login_as(FactoryBot.create(:person))
    creator = FactoryBot.create(:person)
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
    assert_equal 47, updated_sample.get_attribute_value(:age)
    assert_nil updated_sample.get_attribute_value(:weight)
    assert_equal 'M13 9QL', updated_sample.get_attribute_value(:postcode)
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'associate with project on create from form' do
    person = FactoryBot.create(:person_in_multiple_projects)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
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
    person = FactoryBot.create(:person_in_multiple_projects)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
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
    person = FactoryBot.create(:person_in_multiple_projects)
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
    person = FactoryBot.create(:person_in_multiple_projects)
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
    person = FactoryBot.create(:person)
    login_as(person)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :success
  end

  test 'non contributor cannot view' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    login_as(other_person)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :forbidden
  end

  test 'anonymous cannot view' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :show, params: { id: sample.id }
    assert_response :forbidden
  end

  test 'contributor can edit' do
    person = FactoryBot.create(:person)
    login_as(person)

    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_response :success
  end

  test 'non contributor cannot edit' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    login_as(other_person)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'anonymous cannot edit' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)
    get :edit, params: { id: sample.id }
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'create with sharing from form' do
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                                        data: {
                                            "full name": 'Fred Smith',
                                            "age": '22',
                                            "weight": '22.1',
                                            "postcode": 'M13 9PL'
                                        },
                                        project_ids: [person.projects.first.id] }, policy_attributes: valid_sharing }
    end
    assert sample = assigns(:sample)
    assert_equal person, sample.contributor
    assert sample.can_view?(FactoryBot.create(:person).user)
  end

  test 'create with sharing' do
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: type.id, title: 'My Sample',
                                        data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
                                        project_ids: [person.projects.first.id] }, policy_attributes: valid_sharing }
    end
    assert sample = assigns(:sample)
    assert_equal person, sample.contributor
    assert sample.can_view?(FactoryBot.create(:person).user)
  end

  #FIXME: there is an inconstency between the existing tests, and how the form behaved - see https://jira-bsse.ethz.ch/browse/OPSK-1205
  test 'update with sharing from form' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor = person
    sample.projects = person.projects
    sample.policy = FactoryBot.create(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, 
        params: { id: sample.id, 
                  sample: { title: 'Updated Sample', __sample_data_full_name: 'Jesus Jones', __sample_data_age: '47', __sample_data_postcode: 'M13 9QL', project_ids: [] }, policy_attributes: valid_sharing }

    assert sample = assigns(:sample)
    assert sample.can_view?(other_person.user)
  end

  test 'update with sharing' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor = person
    sample.projects = person.projects
    sample.policy = FactoryBot.create(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, 
        params: { id: sample.id, 
                  sample: { title: 'Updated Sample', data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' }, project_ids: [] }, policy_attributes: valid_sharing }

    assert sample = assigns(:sample)
    assert sample.can_view?(other_person.user)
  end

  test 'filter by sample_type route' do
    assert_routing 'sample_types/7/samples', controller: 'samples', action: 'index', sample_type_id: '7'
  end

  test 'filter by tempalte route' do
    assert_routing 'templates/7/samples', controller: 'samples', action: 'index', template_id: '7'
  end

  test 'filter by sample type' do
    sample_type1 = FactoryBot.create(:simple_sample_type)
    sample_type2 = FactoryBot.create(:simple_sample_type)
    sample1 = FactoryBot.create(:sample, sample_type: sample_type1, policy: FactoryBot.create(:public_policy), 
                                         title: 'SAMPLE 1')
    sample2 = FactoryBot.create(:sample, sample_type: sample_type2, policy: FactoryBot.create(:public_policy), 
                                         title: 'SAMPLE 2')

    get :index, params: { sample_type_id: sample_type1.id }
    assert_response :success
    assert samples = assigns(:samples)
    assert_includes samples, sample1
    refute_includes samples, sample2
  end

  test 'filter by template' do
    template1 = FactoryBot.create(:template, policy: FactoryBot.create(:public_policy ))
    template2 = FactoryBot.create(:template, policy: FactoryBot.create(:public_policy ))
    sample_type1 = FactoryBot.create(:simple_sample_type, template_id: template1.id)
    sample_type2 = FactoryBot.create(:simple_sample_type, template_id: template2.id)
    sample1 = FactoryBot.create(:sample, sample_type: sample_type1, policy: FactoryBot.create(:public_policy), 
                                         title: 'SAMPLE 1')
    sample2 = FactoryBot.create(:sample, sample_type: sample_type2, policy: FactoryBot.create(:public_policy), 
                                         title: 'SAMPLE 2')

    get :index, params: { template_id: template1.id }
    assert_response :success
    assert samples = assigns(:samples)
    assert_includes samples, sample1
    refute_includes samples, sample2
  end

  test 'should get table view for sample type' do
    person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:simple_sample_type)
    2.times do # public
      FactoryBot.create(:sample, sample_type: sample_type, contributor: person, 
                                 policy: FactoryBot.create(:private_policy))
    end
    3.times do # private
      FactoryBot.create(:sample, sample_type: sample_type, policy: FactoryBot.create(:private_policy))
    end

    login_as(person.user)

    get :index, params: { sample_type_id: sample_type.id }

    assert_response :success

    assert_select '#samples-table tbody tr', count: 2
  end

  test 'should get table view for template' do
    person = FactoryBot.create(:person)
    template =  FactoryBot.create(:template, policy: FactoryBot.create(:public_policy ))
    sample_type = FactoryBot.create(:simple_sample_type, template_id: template.id)
    2.times do # public
      FactoryBot.create(:sample, sample_type: sample_type, contributor: person, 
                                 policy: FactoryBot.create(:private_policy))
    end
    3.times do # private
      FactoryBot.create(:sample, sample_type: sample_type, policy: FactoryBot.create(:private_policy))
    end

    login_as(person.user)

    get :index, params: { template_id: template.id }

    assert_response :success

    assert_select '#samples-table tbody tr', count: 2
  end

  test 'show table with a boolean sample' do
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:simple_sample_type)
    FactoryBot.create(:sample_attribute, title: 'bool',
                      sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: false, sample_type: type)
    type.save!
    sample = FactoryBot.create(:sample, sample_type: type, contributor: person)
    sample.set_attribute_value(:the_title, 'ttt')
    sample.set_attribute_value(:bool, true)
    sample.save!
    get :index, params: { sample_type_id: type.id }
    assert_response :success
  end

  test 'filtering for association forms' do
    person = FactoryBot.create(:person)
    FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy), title: 'fish')
    FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy), title: 'frog')
    FactoryBot.create(:sample, contributor: person, policy: FactoryBot.create(:public_policy), title: 'banana')
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
    person = FactoryBot.create(:person)
    login_as(person.user)
    sample_type = FactoryBot.create(:strain_sample_type)
    strain = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.save!

    get :show, params: { id: sample }

    assert_response :success
    assert_select 'p a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'strains show up in related items' do
    person = FactoryBot.create(:person)
    login_as(person.user)
    sample_type = FactoryBot.create(:strain_sample_type)
    strain = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person, project_ids: [person.projects.first.id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.save!

    get :show, params: { id: sample }

    assert_response :success
    assert_select 'div.related-items a[href=?]', strain_path(strain), text: /#{strain.title}/
  end

  test 'cannot access when disabled' do
    person = FactoryBot.create(:person)
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
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:patient_sample, contributor: person)
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
    person = FactoryBot.create(:person)
    login_as(person.user)

    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = FactoryBot.create(:patient_sample, 
                                      sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

    sample = Sample.create!(sample_type: sample_type, project_ids: person.projects.map(&:id),
                            data: { title: 'Linking sample',
                                    patient: linked_sample.id })

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
    person = FactoryBot.create(:person)
    login_as(person.user)

    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = FactoryBot.create(:patient_sample, 
                                      sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

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

    assert_select 'div.related-items #resources-shown-count a[href=?]', sample_samples_path(sample), text: "2 Samples"
    assert_select 'div.related-items #advanced-search-link a[href=?]', sample_samples_path(sample), 
                  text: "Advanced Samples list for this Sample with search and filtering"
  end

  test 'related samples index page works correctly' do
    person = FactoryBot.create(:person)
    login_as(person.user)

    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: person.projects.map(&:id))
    linked_sample = FactoryBot.create(:patient_sample, 
                                      sample_type: sample_type.sample_attributes.last.linked_sample_type, contributor: person)

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

  test 'Referring samples show linked sample type if permitted in show page' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample,
                               policy: FactoryBot.create(:private_policy,
                                                         permissions: [FactoryBot.create(:permission,
                                                                                         contributor: person,
                                                                                         access_type: Policy::VISIBLE)]))
    sample_type = sample.sample_type
    login_as(person.user)

    assert sample.can_view?
    refute sample_type.can_view?

    get :show, params: { id:sample.id }
    assert_response :success

    # Referring samples don't show the link to the sample type because the sample type is not visible
    assert_select 'a[href=?]', sample_type_path(sample_type), text: /#{sample_type.title}/, count: 0

    sample2 = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
    sample_type2 = sample2.sample_type
    sample_type2.update(contributor: person)

    assert sample2.can_view?
    assert sample_type2.can_view?

    get :show, params: { id: sample2.id }
    assert_response :success

    # Referring sample shows the link to the sample type because the sample type is visible
    assert_select 'a[href=?]', sample_type_path(sample_type2), text: /#{sample_type2.title}/

  end

  test 'referring samples shows the linked sample type links in list items' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample,
                               policy: FactoryBot.create(:private_policy,
                                                         permissions: [FactoryBot.create(:permission,
                                                                                         contributor: person,
                                                                                         access_type: Policy::VISIBLE)]))
    sample_type = sample.sample_type
    sample2 = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
    sample_type2 = sample2.sample_type
    login_as(person.user)
    sample_type2.update(contributor: person)

    assert sample.can_view?
    refute sample_type.can_view?

    assert sample2.can_view?
    assert sample_type2.can_view?

    get :index

    # Since the Sample Type is not visible, the link is not rendered
    assert_select 'a[href=?]', sample_type_path(sample_type), text: /#{sample_type.title}/, count: 0

    # The Sample Type is visible, so the link is rendered
    assert_select 'a[href=?]', sample_type_path(sample_type2), text: /#{sample_type2.title}/

  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('sample')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, contributor:person)
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
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, 
                               policy: FactoryBot.create(:private_policy, 
                                                         permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert sample.can_edit?
    refute sample.can_manage?
    get :manage, params: {id:sample}
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    sample = FactoryBot.create(:sample, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

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
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = FactoryBot.create(:person)


    sample = FactoryBot.create(:sample, projects: [proj1], policy:FactoryBot.create(:private_policy,
                                                                                    permissions: [FactoryBot.create(:permission,
                                                                                                                    contributor:person, access_type:Policy::EDITING)]))

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

  test 'manage_update does not invalidate source data' do
    proj=FactoryBot.create(:project)
    person = FactoryBot.create(:person, project:proj)
    other_person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample_from_file, contributor: person)

    login_as(person)
    patch :manage_update, params: { id: sample,
                                    sample: { project_ids: [proj.id] },
                                    policy_attributes: { access_type: Policy::VISIBLE,
                                                         permissions_attributes: { '1' => {
                                                           contributor_type: 'Person',
                                                           contributor_id: other_person.id,
                                                           access_type: Policy::MANAGING
                                                         } } } }
    assert_redirected_to sample
    sample.reload
    assert_equal Policy::VISIBLE, sample.policy.access_type
    assert_equal 1, sample.policy.permissions.count
    assert sample.edit_count.zero?

    get :show, params: { id: sample.id }
    assert_response :success
    assert_select 'span.label-danger', text: /No longer valid/, count: 0
  end

  test 'should create with discussion link' do
    person = FactoryBot.create(:person)
    login_as(person)

    type = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))

    sample =  {sample_type_id: type.id,
               data: { 'full name': 'Fred Smith', age: '22', weight: '22.1', postcode: 'M13 9PL' },
               project_ids: [person.projects.first.id],
               discussion_links_attributes: [{url: "http://www.slack.com/"}]}
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
    asset_link = FactoryBot.create(:discussion_link)
    sample = FactoryBot.create(:sample, discussion_links: [asset_link], 
                                        policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],sample.discussion_links
    get :show, params: { id: sample }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update document with new discussion link' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, contributor: person)
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
    person = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type)
    assay = FactoryBot.create(:assay, contributor: person)
    assert_difference('Sample.count', 2) do
      assert_difference('AssayAsset.count', 1) do
          post :batch_create, params: { data: [
            { ex_id: "1", data: { type: "samples",
                                  attributes: { attribute_map: { "full name": 'Fred Smith', "age": '22', 
                                                                 "weight": '22.1', "postcode": 'M13 9PL' } },
                                  relationships: { assays: { data: [{ id: assay.id, type: 'assays' }] },
                                                   projects: { data: [{ id: person.projects.first.id, 
                                                                        type: "projects" }] },
                                                   sample_type: { data: { id: type.id, type: "sample_types" } } } } },
            { ex_id: "2", data: { type: "samples",
                                  attributes: { attribute_map: { "full name": 'David Tailor', "age": '33', 
                                                                 "weight": '33.1', "postcode": 'M12 8PL' } },
                                  relationships: { projects: { data: [{ id: person.projects.first.id, type: "projects" }] },
                                                   sample_type: { data: { id: type.id, 
                                                                          type: "sample_types" } } } } }] }
      end
    end

    # For the Single Page to work properly, these must be included in the response
    assert response.body.include?('results')
    assert response.body.include?('errors')
    assert response.body.include?('status')

    samples = Sample.last(2)
    sample1 = samples.first
    assert_equal 'Fred Smith', sample1.title
    assert_equal 'Fred Smith', sample1.get_attribute_value('full name')
    assert_equal 22, sample1.get_attribute_value(:age)
    assert_equal 22.1, sample1.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample1.get_attribute_value(:postcode)
    assert_equal [assay], sample1.assays

    sample2 = samples.last
    assert_equal 'David Tailor', sample2.title
    assert_equal 'David Tailor', sample2.get_attribute_value('full name')
    assert_equal 33, sample2.get_attribute_value(:age)
    assert_equal 33.1, sample2.get_attribute_value(:weight)
    assert_equal 'M12 8PL', sample2.get_attribute_value(:postcode)
  end

  test 'terminate batch_create if error' do
    person = FactoryBot.create(:person)
    creator = FactoryBot.create(:person)
    login_as(person)
    type = FactoryBot.create(:patient_sample_type)
    assert_difference('Sample.count', 0) do
        post :batch_create, params: {data: [
        {ex_id: "1",data:{type: "samples", attributes:{attribute_map:{"full name": 'Fred Smith', "age": '22', "weight": '22.1' ,"postcode": 'M13 9PL'}},
                          tags: nil,relationships:{projects: {data:[{id: person.projects.first.id, type: "projects"}]},
                                                   sample_type: { data:{id: type.id, type: "sample_types"}}}}},
        {ex_id: "2", data:{type: "samples",attributes:{attribute_map:{"wrong attribute": 'David Tailor', "age": '33', "weight": '33.1' ,"postcode": 'M12 8PL'}},
                           tags: nil,relationships:{projects: {data:[{id: person.projects.first.id, type: "projects"}]},
                                                    sample_type: {data:{id: type.id, type: "sample_types"}}}}}]}
    end

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["errors"].length
    assert_equal "2", json_response["errors"][0]["ex_id"].to_s
  end


  test 'batch_update' do
    login_as(FactoryBot.create(:person))
    creator = FactoryBot.create(:person)
    sample1 = populated_patient_sample
    sample2 = populated_patient_sample
    type_id1 = sample1.sample_type.id
    type_id2 = sample2.sample_type.id
    assert_empty sample1.creators

    assert_no_difference('Sample.count') do
      put :batch_update, params: {data: [
        {id: sample1.id, 
         data: {type: "samples", 
                attributes: { attribute_map: { "full name": 'Alfred Marcus', "age": '22', "weight": '22.1' }, 
                              creator_ids: [creator.id]}}},
        {id: sample2.id, 
         data: {type: "samples", 
                attributes: { attribute_map: { "full name": 'David Tailor', "age": '33', "weight": '33.1' }, 
                              creator_ids: [creator.id]}}}]}
      assert_equal [creator], sample1.creators
    end

    # For the Single Page to work properly, these must be included in the response
    assert response.body.include?('errors')
    assert response.body.include?('status')

    samples = Sample.limit(2)

    first_updated_sample = samples[0]
    assert_equal type_id1, first_updated_sample.sample_type.id
    assert_equal 'Alfred Marcus', first_updated_sample.title
    assert_equal 'Alfred Marcus', first_updated_sample.get_attribute_value('full name')
    assert_equal 22, first_updated_sample.get_attribute_value(:age)
    assert_nil first_updated_sample.get_attribute_value(:postcode)
    assert_equal 22.1, first_updated_sample.get_attribute_value(:weight)

    last_updated_sample = samples[1]
    assert_equal type_id2, last_updated_sample.sample_type.id
    assert_equal 'David Tailor', last_updated_sample.title
    assert_equal 'David Tailor', last_updated_sample.get_attribute_value('full name')
    assert_equal 33, last_updated_sample.get_attribute_value(:age)
    assert_nil last_updated_sample.get_attribute_value(:postcode)
    assert_equal 33.1, last_updated_sample.get_attribute_value(:weight)
  end

  test 'batch_delete' do
    person = FactoryBot.create(:person)
    sample1 = FactoryBot.create(:patient_sample, contributor: person)
    sample2 = FactoryBot.create(:patient_sample, contributor: person)
    type1 = sample1.sample_type
    type2 = sample1.sample_type
    login_as(person.user)
    assert sample1.can_delete?
    assert sample2.can_delete?
    assert_difference('Sample.count', -2) do
      delete :batch_delete, params: { data: [ {id: sample1.id}, {id: sample2.id}] }
    end

    # For the Single Page to work properly, these must be included in the response
    # No errors should occur in this request, meaning status should be 'ok'
    response_body = JSON.parse(response.body)
    assert response_body.key?('errors')
    assert_empty response_body['errors']
    assert response_body.key?('status')
    assert_equal response_body['status'], 'ok'
  end

  test 'batch delete hidden samples' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    sample_type = FactoryBot.create(:min_sample_type, contributor: person, projects: [project])
    authorized_sample = FactoryBot.create(:sample, contributor: person, sample_type: sample_type, data: { full_name: 'John Smith' })
    assert_equal sample_type.samples.count, 1

    login_as(person)
    # One of the samples is a hidden sample and has '#HIDDEN' for id
    assert_no_difference('Sample.count') do
      delete_data = [
        { ex_id: "#{sample_type.id}-#{1}", id: "#HIDDEN" },
        { ex_id: "#{sample_type.id}-#{2}", id: authorized_sample.id }
      ]
      delete :batch_delete, params: { data: delete_data }
    end

    response_body = JSON.parse(response.body)
    assert_equal 1, response_body['errors'].length
    error = response_body['errors'][0]
    assert_equal error, { 'ex_id' => "#{sample_type.id}-#{1}", 'error' => 'Sample with id \'#HIDDEN\' not found.' }
  end

  test 'batch delete inexisting samples' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    sample_type = FactoryBot.create(:min_sample_type, contributor: person, projects: [project])
    authorized_sample = FactoryBot.create(:sample, contributor: person, sample_type: sample_type, data: { full_name: 'John Smith' })
    assert_equal sample_type.samples.count, 1

    login_as(person)
    # One of the samples is a hidden sample and has '#HIDDEN' for id
    random_id = rand((10000..100000))
    assert_no_difference('Sample.count') do
      delete_data = [
        { ex_id: "#{sample_type.id}-#{1}", id: random_id },
        { ex_id: "#{sample_type.id}-#{2}", id: authorized_sample.id }
      ]
      delete :batch_delete, params: { data: delete_data }
    end

    response_body = JSON.parse(response.body)
    assert_equal 1, response_body['errors'].length
    error = response_body['errors'][0]
    assert_equal error, { 'ex_id' => "#{sample_type.id}-#{1}", 'error' => "Sample with id '#{random_id}' not found." }
  end

  test 'batch delete unauthorized samples' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    other_person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:min_sample_type, contributor: person, projects: [project])
    authorized_sample = FactoryBot.create(:sample, contributor: person, sample_type: sample_type, data: { full_name: 'John Smith' })
    unauthorized_sample = FactoryBot.create(:sample, contributor: other_person, sample_type: sample_type, data: { full_name: 'Jane Doe' })
    assert_equal sample_type.samples.count, 2

    login_as(person)
    # One of the samples is a hidden sample and has '#HIDDEN' for id
    assert_no_difference('Sample.count') do
      delete_data = [
        { ex_id: "#{sample_type.id}-#{1}", id: unauthorized_sample.id },
        { ex_id: "#{sample_type.id}-#{2}", id: authorized_sample.id }
      ]
      delete :batch_delete, params: { data: delete_data }
    end

    response_body = JSON.parse(response.body)
    assert_equal 1, response_body['errors'].length
    error = response_body['errors'][0]
    assert_equal error, { 'ex_id' => "#{sample_type.id}-#{1}", 'error' => "Unauthorized to delete Sample with id '#{unauthorized_sample.id}'." }
  end

  test 'JS request does not raise CORS error' do
    sample = FactoryBot.create(:sample)
    login_as(sample.contributor)

    assert_raises(ActionController::UnknownFormat) do
      get :show, params: { id: sample.id, format: :js }
    end
  end

  test 'should show query form' do
    with_config_value(:isa_json_compliance_enabled, true) do
      get :query_form
      assert_response :success
    end
  end

  test 'should populate user projects in query form' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      person.add_to_project_and_institution(FactoryBot.create(:project), FactoryBot.create(:institution))
      login_as(person)

      get :query_form
      assert_response :success
      assert_select '#projects' do |options|
        assert_select options, 'option', Project.all.length
      end
    end
  end

  test 'should not return private samples with basic query' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)
      template = FactoryBot.create(:template)
      sample_type = FactoryBot.create(:simple_sample_type, template_id: template.id)
      sample1 = FactoryBot.create(:sample, sample_type: sample_type, contributor: person)
      sample2 = FactoryBot.create(:sample, sample_type: sample_type, contributor: person)
      sample3 = FactoryBot.create(:sample, sample_type: sample_type)

      login_as(person)

      post :query, xhr: true, params: { template_id: template.id }
      assert_response :success
      assert result = assigns(:result)
      assert_equal 2, result.length
    end
  end

  test 'create single linked sample' do
    person = FactoryBot.create(:person)
    login_as(person)
    patient = FactoryBot.create(:patient_sample, contributor: person, policy: FactoryBot.create(:public_policy))
    linked_sample_type = FactoryBot.create(:linked_sample_type, project_ids: [person.projects.first.id], policy: FactoryBot.create(:public_policy))
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.save!

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: linked_sample_type.id,
                                        data: {
                                          "title": 'Single Sample',
                                          "patient": ['', patient.id.to_s]
                                        },
                                        project_ids: [person.projects.first.id]} }
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Single Sample', sample.title

    assert_equal [patient], sample.linked_samples
    assert_equal patient.id, sample.get_attribute_value(:patient)['id']

  end

  test 'create multi linked sample' do
    person = FactoryBot.create(:person)
    login_as(person)
    patient = FactoryBot.create(:patient_sample, contributor: person)
    patient2 = FactoryBot.create(:patient_sample, sample_type:patient.sample_type, contributor: person )
    multi_linked_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [person.projects.first.id], policy: FactoryBot.create(:public_policy))
    multi_linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    multi_linked_sample_type.save!

    assert_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: multi_linked_sample_type.id,
                                        data: {
                                          "title": 'Multiple Samples',
                                          "patient": ['',patient.id.to_s, patient2.id.to_s]
                                        },
                                        project_ids: [person.projects.first.id]} }
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'Multiple Samples', sample.title

    assert_equal [patient, patient2], sample.linked_samples
    assert_equal [patient.id, patient2.id], sample.get_attribute_value(:patient).collect{|v| v['id']}

  end

  test 'validates against linking a private sample' do
    person = FactoryBot.create(:person)
    login_as(person)
    patient = FactoryBot.create(:patient_sample, contributor: FactoryBot.create(:person), 
                                                 policy: FactoryBot.create(:private_policy))

    multi_linked_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [person.projects.first.id], policy: FactoryBot.create(:public_policy))
    multi_linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    multi_linked_sample_type.save!

    refute patient.can_view?

    assert_no_difference('Sample.count') do
      post :create, params: { sample: { sample_type_id: multi_linked_sample_type.id,
                                        data: {
                                          "title": 'Multiple Samples',
                                          "patient": ['',patient.id.to_s]
                                        },
                                        project_ids: [person.projects.first.id]} }
    end
    assert assigns(:sample)
    refute assigns(:sample).valid?

  end

	test 'should return max query result' do
		with_config_value(:isa_json_compliance_enabled, true) do
			person = FactoryBot.create(:person)
			project = FactoryBot.create(:project)

			login_as(person)

			template1 = FactoryBot.create(:isa_source_template)
			template2 = FactoryBot.create(:isa_sample_collection_template)
			template3 = FactoryBot.create(:isa_assay_material_template)

			# Add extra non-text attributes
			[template1, template2, template3].each do |template|
				isa_tag = if template.level == 'study source'
										FactoryBot.build(:source_characteristic_isa_tag)
									elsif template.level == 'study sample'
										FactoryBot.build(:sample_characteristic_isa_tag)
									elsif template.level == 'assay - material'
										FactoryBot.build(:other_material_characteristic_isa_tag)
									else
										FactoryBot.build(:data_file_comment_isa_tag)
									end
				boolean_attribute = FactoryBot.create(:boolean_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - boolean")
				sop_attribute = FactoryBot.create(:sop_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - sop")
				strain_attribute = FactoryBot.create(:strain_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - strain")
				datafile_attribute = FactoryBot.create(:data_file_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - data file")
				float_attribute = FactoryBot.create(:float_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - float")
				datetime_attribute = FactoryBot.create(:datetime_template_attribute, isa_tag: isa_tag, title: "#{isa_tag.title} - datetime")
				template.template_attributes << [boolean_attribute, sop_attribute, strain_attribute, datafile_attribute,
																				 float_attribute, datetime_attribute]
				template.save
			end

			type1 = FactoryBot.create(:simple_sample_type, contributor: person, project_ids: [project.id],
																title: 'Source sample type', template_id: template1.id)
			type1.create_sample_attributes_from_isa_template(template1)

			type2 = FactoryBot.create(:simple_sample_type, contributor: person, project_ids: [project.id],
																title: 'Sample collection sample type', template_id: template2.id)
			type2.create_sample_attributes_from_isa_template(template2, type1)

			type3 = FactoryBot.create(:simple_sample_type, contributor: person, project_ids: [project.id],
																title: 'Assay material sample type', template_id: template3.id)
			type3.create_sample_attributes_from_isa_template(template3, type2)

			# Create strains
			strain1 = FactoryBot.create(:min_strain, projects: [project], title: 'Saccharomyces cerevisiae YGL118W', organism: FactoryBot.create(:organism, title: 'Saccharomyces cerevisiae'))
			strain2 = FactoryBot.create(:min_strain, projects: [project], title: 'SARS-CoV-2', organism: FactoryBot.create(:organism, title: 'Coronavirus'))
			strain3 = FactoryBot.create(:min_strain, projects: [project], title: 'Arabidopsis thaliana', organism: FactoryBot.create(:organism, title: 'Arabidopsis'))

			# Create data_files
			df1 = FactoryBot.create(:min_data_file, contributor: person, project_ids: [project.id], title: "Excel spreadsheet")
			df2 = FactoryBot.create(:min_data_file, contributor: person, project_ids: [project.id], title: "Powerpoint presentation")
			df3 = FactoryBot.create(:min_data_file, contributor: person, project_ids: [project.id], title: "Zip file")

			sample1 = FactoryBot.create :sample, title: 'sample1',
																	sample_type: type1,
																	project_ids: [project.id],
																	contributor: person,
																	data: { 'Source Name': 'Source Name',
																					'Source Characteristic 1': 'Source Characteristic 1',
																					'Source Characteristic 2': "Cox's Orange Pippin",
																					'source_characteristic - boolean': true,
																					'source_characteristic - strain': strain1,
																					'source_characteristic - data file': df1,
																					'source_characteristic - float': 0.721,
																					'source_characteristic - datetime': '01-01-2020',
																	}

			sampling_sop = FactoryBot.create(:public_sop, title: 'Sampling SOP')
			sample2 = FactoryBot.create :sample, title: 'sample2', sample_type: type2, project_ids: [project.id], contributor: person,
																	data: { Input: [sample1.id],
																					'sample collection': 'sample collection',
																					'sample collection parameter value 1': 'sample collection parameter value 1',
																					'Sample Name': 'sample name',
																					'sample characteristic 1': 'sample characteristic 1',
																					'sample_characteristic - boolean': false,
																					'sample_characteristic - sop': sampling_sop,
																					'sample_characteristic - strain': strain2,
																					'sample_characteristic - data file': df2,
																					'sample_characteristic - float': 0.965,
																					'sample_characteristic - datetime': '02-02-2022 15:00'
																	}

			# sample3
			material_assay_sop = FactoryBot.create(:public_sop, title: 'Material Assay SOP')
			FactoryBot.create :sample, title: 'sample3', sample_type: type3, project_ids: [project.id], contributor: person,
												data: { Input: [sample2.id],
																'Protocol Assay 1': 'Protocol Assay 1',
																'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
																'Extract Name': 'Extract Name',
																'other material characteristic 1': 'other material characteristic 1',
																'other_material_characteristic - boolean': true,
																'other_material_characteristic - sop': material_assay_sop,
																'other_material_characteristic - strain': strain3,
																'other_material_characteristic - data file': df3,
																'other_material_characteristic - float': 0.843,
																'other_material_characteristic - datetime': '04-2024'
												}

			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2.template_attributes.second.id,
				template_attribute_value: 'collection',
				input_template_id: template1.id,
				input_attribute_id: template1.template_attributes.third.id,
				input_attribute_value: "x's",
				output_template_id: template3.id,
				output_attribute_id: template3.template_attributes.second.id,
				output_attribute_value: '1'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Do the same query but with random casing to check if case-insensitive
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2.template_attributes.second.id,
				template_attribute_value: 'ColLecTion',
				input_template_id: template1.id,
				input_attribute_id: template1.template_attributes.third.id,
				input_attribute_value: "x's",
				output_template_id: template3.id,
				output_attribute_id: template3.template_attributes.second.id,
				output_attribute_value: '1'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on booleans
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::BOOLEAN }
																 .id,
				template_attribute_value: 'false',
				input_template_id: template1.id,
				input_attribute_id: template1
															.template_attributes
															.detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::BOOLEAN }
															.id,
				input_attribute_value: 'true',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::BOOLEAN }
															 .id,
				output_attribute_value: 'true',
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on SOPs
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.seek_sop? }
																 .id,
				template_attribute_value: 'sampling',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.seek_sop? }
															 .id,
				output_attribute_value: 'assay'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on Strains
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.seek_strain? }
																 .id,
				template_attribute_value: 'SARs',
				input_template_id: template1.id,
				input_attribute_id: template1
															.template_attributes
															.detect { |tat| tat.sample_attribute_type.seek_strain? }
															.id,
				input_attribute_value: 'cerevis',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.seek_strain? }
															 .id,
				output_attribute_value: 'thaliana'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on data files
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.seek_data_file? }
																 .id,
				template_attribute_value: 'powerp',
				input_template_id: template1.id,
				input_attribute_id: template1
															.template_attributes
															.detect { |tat| tat.sample_attribute_type.seek_data_file? }
															.id,
				input_attribute_value: 'spread',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.seek_data_file? }
															 .id,
				output_attribute_value: 'zip'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on float number
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::FLOAT }
																 .id,
				template_attribute_value: '65',
				input_template_id: template1.id,
				input_attribute_id: template1
															.template_attributes
															.detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::FLOAT }
															.id,
				input_attribute_value: '0.7',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::FLOAT }
															 .id,
				output_attribute_value: '0'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query on date and time
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2
																 .template_attributes
																 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::DATE_TIME }
																 .id,
				template_attribute_value: '15:00',
				input_template_id: template1.id,
				input_attribute_id: template1
															.template_attributes
															.detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::DATE_TIME }
															.id,
				input_attribute_value: '01-01',
				output_template_id: template3.id,
				output_attribute_id: template3
															 .template_attributes
															 .detect { |tat| tat.sample_attribute_type.base_type == Seek::Samples::BaseType::DATE_TIME }
															 .id,
				output_attribute_value: '2024'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length
			# Query for sample's grandparents
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template3.id,
				template_attribute_id: template3.template_attributes.second.id,
				template_attribute_value: 'Protocol',
				input_template_id: template1.id,
				input_attribute_id: template1.template_attributes.third.id,
				input_attribute_value: "x's"
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Query for sample's grandchildren
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template1.id,
				template_attribute_id: template1.template_attributes.third.id,
				template_attribute_value: "x's",
				output_template_id: template3.id,
				output_attribute_id: template3.template_attributes.second.id,
				output_attribute_value: 'Protocol'
			}

			assert_response :success
			assert result = assigns(:result)
			assert_equal 1, result.length

			# Simple query on 'Input' attribute (SEEK_SAMPLE_MULTI type)
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template2.id,
				template_attribute_id: template2.template_attributes.detect(&:input_attribute?)&.id,
				template_attribute_value: 'source'
			}

			assert_response :success
			result = assigns(:result)
			assert_equal result.length, 1

			# parent query on 'Input' attribute (SEEK_SAMPLE_MULTI type)
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template3.id,
				template_attribute_id: template3.template_attributes.second.id,
				template_attribute_value: 'Protocol',
				input_template_id: template2.id,
				input_attribute_id: template2.template_attributes.detect(&:input_attribute?)&.id,
				input_attribute_value: "source"
			}

			assert_response :success
			result = assigns(:result)
			assert_equal result.length, 1

			# Grandchild query on 'Input' attribute (SEEK_SAMPLE_MULTI type)
			post :query, xhr: true, params: {
				project_ids: [project.id],
				template_id: template1.id,
				template_attribute_id: template1.template_attributes.third.id,
				template_attribute_value: "x's",
				output_template_id: template3.id,
				output_attribute_id: template3.template_attributes.detect(&:input_attribute?)&.id,
				output_attribute_value: 'sample'
			}

			assert_response :success
			result = assigns(:result)
			assert_equal result.length, 1
		end
	end

	test 'form hides private linked multi samples' do
    person = FactoryBot.create(:person)
    login_as(person)

    patient = FactoryBot.create(:patient_sample, contributor: person, policy: FactoryBot.create(:public_policy))
    patient.set_attribute_value('full name','Public Patient')
    patient.save!
    patient2 = FactoryBot.create(:patient_sample, sample_type: patient.sample_type, contributor: person, 
                                                  policy: FactoryBot.create(:private_policy) )
    patient2.set_attribute_value('full name','Private Patient')
    patient2.save!
    multi_linked_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [person.projects.first.id])
    multi_linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    multi_linked_sample_type.save!

    sample = Sample.create(sample_type: multi_linked_sample_type,
                           data: {
                              "title": 'Multiple Samples',
                              "patient": [patient.id.to_s, patient2.id.to_s]
                            },
                           project_ids: [person.projects.first.id],
                           policy: FactoryBot.create(:editing_public_policy)
    )

    person2 = FactoryBot.create(:person)
    login_as(person2)
    assert sample.can_edit?

    get :edit, params: { id: sample.id }
    assert_response :success

    assert_select 'select#sample_data_patient' do
      assert_select 'option[value=?]',patient.id, text:/Public Patient/, count:1
      assert_select 'option[value=?]',patient2.id, text:/Hidden/, count:1
      assert_select 'option[value=?]',patient2.id, text:/Private Patient/, count:0
    end

  end

  test 'form hides private linked single sample' do
    person = FactoryBot.create(:person)
    login_as(person)

    patient = FactoryBot.create(:patient_sample, contributor: person, policy: FactoryBot.create(:private_policy) )
    patient.set_attribute_value('full name','Private Patient')
    patient.save!
    linked_sample_type = FactoryBot.create(:linked_sample_type, project_ids: [person.projects.first.id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.save!

    sample = Sample.create(sample_type: linked_sample_type,
                           data: {
                             "title": 'Single linked sample',
                             "patient": patient.id.to_s
                           },
                           project_ids: [person.projects.first.id],
                           policy: FactoryBot.create(:editing_public_policy)
    )

    person2 = FactoryBot.create(:person)
    login_as(person2)
    assert sample.can_edit?

    get :edit, params: { id: sample.id }
    assert_response :success

    assert_select 'select#sample_data_patient' do
      assert_select 'option[value=?]',patient.id, text:/Hidden/, count:1
      assert_select 'option[value=?]',patient.id, text:/Private Patient/, count:0
    end

  end

  test 'typeahead' do
    person = FactoryBot.create(:person)
    sample1 = FactoryBot.create(:sample, title: 'sample1', contributor: person)
    sample_type = sample1.sample_type

    sample2 = FactoryBot.create(:sample, sample_type: sample_type, title: 'sample2')

    login_as(person)
    assert_equal sample1.sample_type, sample2.sample_type
    assert sample1.can_view?
    refute sample2.can_view?

    get :typeahead, params:{ format: :json, linked_sample_type_id: sample_type.id, q:'samp'}
    assert_response :success
    res = JSON.parse(response.body)['results']

    assert_equal 1, res.count
    assert_equal 'sample1', res.first['text']

  end

  test 'unauthorized users should not do batch operations' do
    sample = FactoryBot.create(:sample)

    post :batch_create
    assert_redirected_to :root
    assert_not_nil flash[:error]

    params = { data: [
      { id: sample.id,
        data: { type: 'samples',
                attributes: { attribute_map: { "full name": 'Alfred Marcus', "age": '22', "weight": '22.1' } } } }
    ] }
    put :batch_update, params: params
    assert_equal JSON.parse(response.body)['status'], 'unprocessable_entity'

    delete :batch_delete, params: { data: [{ id: sample.id }] }
    assert_equal JSON.parse(response.body)['status'], 'unprocessable_entity'
  end

  test 'should show label to say controlled vocab allows free text' do
    login_as(FactoryBot.create(:person))

    type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:apples_controlled_vocab_attribute, is_title: true, title: 'allowed', allow_cv_free_text: true, 
                                                          sample_type: type)
    FactoryBot.create(:apples_controlled_vocab_attribute, title: 'not allowed', allow_cv_free_text: false, 
                                                          sample_type: type)


    get :new, params: { sample_type_id: type.id }
    assert_response :success

    assert_select 'label',text: /allowed/ do
      assert_select 'span.subtle', text:/#{I18n.t('samples.allow_free_text_label_hint')}/
    end

    assert_select 'label',text: /not allowed/ do
      assert_select 'span.subtle', text:/#{I18n.t('samples.allow_free_text_label_hint')}/, count: 0
    end

  end

  test 'should not add a sample to a locked sample type' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)

    sample_type = FactoryBot.create(:simple_sample_type, contributor: person, project_ids: [project.id])

    # lock the sample type by adding a fake update task
    UpdateSampleMetadataJob.perform_later(sample_type, person.user, [])

    get :new, params: { sample_type_id: sample_type.id }
    assert_redirected_to sample_types_path(sample_type)
    assert_equal flash[:error], 'This sample type is locked. You cannot edit the sample.'
  end

  def rdf_test_object
    FactoryBot.create(:max_sample, policy: FactoryBot.create(:public_policy))
  end

  private

  def populated_patient_sample
    person = FactoryBot.create(:person)
    sample = Sample.new title: 'My Sample', policy: FactoryBot.create(:public_policy),
                        project_ids: person.projects.collect(&:id),contributor:person
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    sample.title = 'My sample'
    sample.set_attribute_value('full name', 'Fred Bloggs')
    sample.set_attribute_value(:age, 22)
    sample.save!
    sample
  end

end
