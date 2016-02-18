require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test 'new' do
    login_as(Factory(:person))
    get :new
    assert_response :success
    assert assigns(:sample)
  end

  test 'show' do
    get :show, :id=>populated_patient_sample.id
    assert_response :success
  end

  test 'new with sample type id' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    get :new,sample_type_id:type.id
    assert_response :success
    assert assigns(:sample)
    assert_equal type,assigns(:sample).sample_type
  end

  test 'create' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    assert_difference("Sample.count") do
      post :create,:sample=>{:sample_type_id=>type.id,:title=>"My Sample",:full_name=>"George Osborne",:age=>"22",:weight=>"22.1",:postcode=>"M13 9PL"}
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal "My Sample",sample.title
    assert_equal "George Osborne",sample.full_name
    assert_equal "22",sample.age
    assert_equal "22.1",sample.weight
    assert_equal "M13 9PL",sample.postcode

  end

  test 'edit' do
    login_as(Factory(:person))
    get :edit, :id=>populated_patient_sample.id
    assert_response :success
  end

  test 'update' do
    login_as(Factory(:person))
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_no_difference("Sample.count") do
      put :update,:id=>sample.id,:sample=>{title:"Updated Sample",full_name:'Jesus Jones',age:'47',postcode:"M13 9QL"}
    end

    assert assigns(:sample)
    assert_redirected_to assigns(:sample)
    updated_sample = assigns(:sample)
    updated_sample=Sample.find(updated_sample.id)
    assert_equal type_id,updated_sample.sample_type.id
    assert_equal "Updated Sample",updated_sample.title
    assert_equal "Jesus Jones",updated_sample.full_name
    assert_equal "47",updated_sample.age
    assert_nil updated_sample.weight
    assert_equal "M13 9QL",updated_sample.postcode
  end

  private

  def populated_patient_sample
    sample = Sample.new title:"My Sample"
    sample.sample_type = Factory(:patient_sample_type)
    sample.title="My sample"
    sample.full_name="Fred Bloggs"
    sample.age=22
    sample.save!
    sample
  end

end
