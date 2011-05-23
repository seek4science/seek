require 'test_helper'

class AssetTest < ActiveSupport::TestCase
  fixtures :all
  include ApplicationHelper

  test "creatable classes order" do
    EVENTS_ENABLED=true
    creatables = user_creatable_classes
    assert !creatables.empty?
    assert_equal [DataFile,Model,Publication,Sop,Assay,Investigation,Study,Event],creatables
  end

  test "classifying and authorizing resources" do
    resource_array = []
    sop=sops(:my_first_sop)
    model=models(:teusink)
    data_file=data_files(:picture)
    user=users(:owner_of_my_first_sop)        
    
    sop_version1 = sop.find_version(1)
    model_version2 = model.find_version(2)
    
    resource_array << sop_version1
    resource_array << model_version2
    resource_array << data_file
    
    assert_equal 1, sop.version
    assert_equal 2, model.version
    assert_equal 1, data_file.version
    
        
    result = Asset.classify_and_authorize_resources(resource_array, true, user)    
    
    assert_equal 3, result.length
    
    assert result["Sop"].include?(sop_version1)    
    assert result["Model"].include?(model_version2)
    assert result["DataFile"].include?(data_file)
  end

  test "is publishable" do
    assert Factory(:sop).is_publishable?
    assert Factory(:model).is_publishable?
    assert Factory(:data_file).is_publishable?
    assert !Factory(:assay).is_publishable?
    assert !Factory(:investigation).is_publishable?
    assert !Factory(:study).is_publishable?
    assert !Factory(:event).is_publishable?
    assert !Factory(:publication).is_publishable?
  end

  test "managers" do
    person=Factory(:person)
    person2=Factory(:person,:first_name=>"fred",:last_name=>"bloggs")
    user=Factory(:user)
    sop=Factory(:sop,:contributor=>person)
    assert_equal 1,sop.managers.count
    assert sop.managers.include?(person)

    df=Factory(:data_file,:contributor=>user)
    assert_equal 1,df.managers.count
    assert df.managers.include?(user.person)

    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => user, :access_type => Policy::MANAGING, :policy => policy)
    policy.permissions << Factory(:permission, :contributor => person, :access_type => Policy::EDITING, :policy => policy)
    assay=Factory(:assay,:policy=>policy,:owner=>person2)
    assert_equal 2,assay.managers.count
    assert assay.managers.include?(user.person)
    assert assay.managers.include?(person2)

    #this is liable to change when Project contributors are handled
    p1=Factory(:project)
    p2=Factory(:project)
    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => p1, :access_type => Policy::MANAGING, :policy => policy)
    model=Factory(:model,:policy=>policy,:contributor=>p2)
    assert model.managers.empty?
  end


end