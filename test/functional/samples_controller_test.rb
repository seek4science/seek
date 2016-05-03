require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include HtmlHelper

  test 'index' do
    Factory(:sample,:policy=>Factory(:public_policy))
    get :index
    assert_response :success
    assert_select '#samples-table table', count: 0
  end

  test 'new' do
    login_as(Factory(:person))
    get :new
    assert_response :success
    assert assigns(:sample)
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
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' } }
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'George Osborne', sample.title
    assert_equal 'George Osborne', sample.get_attribute(:full_name)
    assert_equal '22', sample.get_attribute(:age)
    assert_equal '22.1', sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)
    assert_equal person.user,sample.contributor
  end

  test 'create and update with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute,:title=>"bool",:sample_attribute_type=>Factory(:boolean_sample_attribute_type),:required=>false, :sample_type => type)
    type.save!
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, data: { the_title: 'ttt', bool:'1' } }
    end
    assert_not_nil sample=assigns(:sample)
    assert_equal 'ttt',sample.get_attribute(:the_title)
    assert_equal true,sample.get_attribute(:bool)
    assert_no_difference('Sample.count') do
      put :update, id:sample.id,sample: { data: { the_title: 'ttt', bool:'0' } }
    end
    assert_not_nil sample=assigns(:sample)
    assert_equal 'ttt',sample.get_attribute(:the_title)
    assert_equal false,sample.get_attribute(:bool)
  end

  test 'show sample with boolean' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute,:title=>"bool",:sample_attribute_type=>Factory(:boolean_sample_attribute_type),:required=>false, :sample_type => type)
    type.save!
    sample=Factory(:sample,:sample_type=>type)
    sample.set_attribute(:the_title, 'ttt')
    sample.set_attribute(:bool, true)
    sample.save!
    get :show,id:sample.id
    assert_response :success

  end

  test 'edit' do
    login_as(Factory(:person))
    get :edit, id: populated_patient_sample.id
    assert_response :success
  end

  test 'update' do
    login_as(Factory(:person))
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_no_difference('Sample.count') do
      put :update, id: sample.id, sample: { data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' } }
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
  end

  test 'associate with project on create' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert person.projects.count >= 3 #incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample', data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' }, project_ids:project_ids }
    end
    assert sample=assigns(:sample)
    assert_equal person.projects[0..1].sort,sample.projects.sort
  end

  test 'associate with project on update' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    sample = populated_patient_sample
    assert_empty sample.projects
    assert person.projects.count >= 3 #incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)

    put :update, id: sample.id, sample: { title: 'Updated Sample',  data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' }, project_ids:project_ids }

    assert sample=assigns(:sample)
    assert_equal person.projects[0..1].sort,sample.projects.sort

  end

  test 'contributor can view' do
    person = Factory(:person)
    login_as(person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :success
  end

  test 'non contributor cannot view' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :forbidden
  end

  test 'anonymous cannot view' do
    person = Factory(:person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :forbidden
  end

  test 'contributor can edit' do
    person = Factory(:person)
    login_as(person)

    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_response :success
  end

  test 'non contributor cannot edit' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'anonymous cannot edit' do
    person = Factory(:person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'create with sharing' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)


    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample',  data: { full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' }, project_ids:[] },:sharing=>valid_sharing
    end
    assert sample=assigns(:sample)
    assert_equal person.user,sample.contributor
    assert_equal Policy::ALL_USERS,sample.policy.sharing_scope
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

    put :update, id: sample.id, sample: { title: 'Updated Sample',  data: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' },project_ids:[] },:sharing=>valid_sharing

    assert sample=assigns(:sample)
    assert_equal Policy::ALL_USERS,sample.policy.sharing_scope
    assert sample.can_view?(other_person.user)
  end

  test 'filter by sample_type route' do
    assert_routing "sample_types/7/samples",{controller:"samples",action:"index",sample_type_id:"7"}
  end

  test 'filter by sample type' do
    sample_type1=Factory(:simple_sample_type)
    sample_type2=Factory(:simple_sample_type)
    sample1=Factory(:sample,:sample_type=>sample_type1,:policy=>Factory(:public_policy),:title=>"SAMPLE 1")
    sample2=Factory(:sample,:sample_type=>sample_type2,:policy=>Factory(:public_policy),:title=>"SAMPLE 2")

    get :index,:sample_type_id=>sample_type1.id
    assert_response :success
    assert samples = assigns(:samples)
    assert_includes samples, sample1
    refute_includes samples, sample2
  end

  test 'extract from data file with multiple matching sample types' do
    person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:sample_type_populated_template_content_blob),
                        :policy=>Factory(:private_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference("Sample.count",0) do
      post :extract_from_data_file, :data_file_id=>data_file.id
    end

    assert_redirected_to select_sample_type_data_file_path(data_file) # Test for this is in data_files_controller_test
  end

  test 'extract from data file prompts confirmation' do
    person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:sample_type_populated_template_content_blob),
                        :policy=>Factory(:private_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference("Sample.count",0) do
      post :extract_from_data_file, :data_file_id=>data_file.id
    end

    assert_select '#accepted table tbody tr', count: 3
    assert_select '#rejected table tbody tr', count: 1
    assert_select 'form input[name=confirm]', count: 1
  end

  test 'extract from data file' do
    person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:sample_type_populated_template_content_blob),
                        :policy=>Factory(:private_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference("Sample.count",3) do
      post :extract_from_data_file, :data_file_id=>data_file.id, :confirm=>'true'
    end

    assert (samples = assigns(:samples))
    assert assigns(:rejected_samples)
    assert_equal 3, samples.count
    assert_equal 1, assigns(:rejected_samples).count
    assert_equal "Bob", assigns(:rejected_samples).first.get_attribute(:full_name)

    assert_select '#accepted table tbody tr', count: 3
    assert_select '#rejected table tbody tr', count: 1
    assert_select 'form input[name=confirm]', count: 0

    samples.each do |sample|
      assert_equal data_file, sample.originating_data_file
    end

    data_file.reload

    assert_equal samples.sort, data_file.extracted_samples.sort
  end

  test "can't extract from data file if no permissions" do
    person = Factory(:person)
    another_person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:sample_type_populated_template_content_blob), :policy=>Factory(:private_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    login_as(another_person)

    assert_no_difference("Sample.count") do
      post :extract_from_data_file, :data_file_id=>data_file.id
    end

    assert_redirected_to data_file_path(data_file)
    assert_not_empty flash[:error]
  end

  test "should get table view for data file" do
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

  test "should get table view for sample type" do
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

  test "show table with a boolean sample" do
    person = Factory(:person)
    login_as(person)
    type = Factory(:simple_sample_type)
    type.sample_attributes << Factory(:sample_attribute,:title=>"bool",:sample_attribute_type=>Factory(:boolean_sample_attribute_type),:required=>false, :sample_type => type)
    type.save!
    sample=Factory(:sample,:sample_type=>type)
    sample.set_attribute(:the_title, 'ttt')
    sample.set_attribute(:bool, true)
    sample.save!
    get :index,sample_type_id:type.id
    assert_response :success
  end

  test 'filtering for association forms' do
    person = Factory(:person)
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: "fish")
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: "frog")
    Factory(:sample, contributor: person.user, policy: Factory(:public_policy), title: "banana")
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

    sample = Sample.new(sample_type: sample_type, contributor: person)
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.save!

    get :show, id: sample

    assert_response :success
    assert_select "p a[href=?]", strain_path(strain), text: /#{strain.title}/
  end

  test 'strains show up in related items' do
    person = Factory(:person)
    login_as(person.user)
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, contributor: person)
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.save!

    get :show, id: sample

    assert_response :success
    assert_select "div.related-items a[href=?]", strain_path(strain), text: /#{strain.title}/
  end

  test 'strain samples successfully extracted from spreadsheet' do
    person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:strain_sample_data_content_blob),
                        :policy=>Factory(:private_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:strain_sample_data_content_blob)
    sample_type.build_attributes_from_template
    attribute_type = sample_type.sample_attributes.last
    attribute_type.sample_attribute_type = Factory(:strain_sample_attribute_type)
    attribute_type.required = true
    sample_type.save!

    assert_difference("Sample.count", 3) do
      post :extract_from_data_file, :data_file_id=>data_file.id, :confirm=>'true'
    end

    assert (samples = assigns(:samples))
    assert assigns(:rejected_samples)
    assert_equal 3, samples.count
    assert_equal 1, assigns(:rejected_samples).count

    strain = Strain.find_by_title('default')
    assert_select '#accepted table tbody tr:nth-child(1) td:last-child a[href=?]', strain_path(strain), text: 'default'
    assert_select '#accepted table tbody tr:nth-child(2) td:last-child a[href=?]', strain_path(strain), text: 'default'
    assert_select '#accepted table tbody tr:nth-child(3) td:last-child span.none_text', text: '1234'
    assert_select '#rejected table tbody tr:nth-child(1) td:last-child span.none_text', text: 'Not specified'

    assert_equal samples.sort, data_file.extracted_samples.sort
  end

  private

  def populated_patient_sample
    sample = Sample.new title: 'My Sample', policy:Factory(:public_policy), contributor:Factory(:person)
    sample.sample_type = Factory(:patient_sample_type)
    sample.title = 'My sample'
    sample.set_attribute(:full_name, 'Fred Bloggs')
    sample.set_attribute(:age, 22)
    sample.save!
    sample
  end
end
