require File.dirname(__FILE__) + '/../test_helper'

class AssetTest < ActiveSupport::TestCase
  fixtures :all
  
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
    
    #assert Authorization.is_authorized?("show", nil, sop_version1.asset, user)
        
    result = Asset.classify_and_authorize_resources(resource_array, true, user)    
    
    assert_equal 3, result.length
    
    assert result["Sop"].include?(sop_version1)    
    assert result["Model"].include?(model_version2)
    assert result["DataFile"].include?(data_file)
  end
  

  
end