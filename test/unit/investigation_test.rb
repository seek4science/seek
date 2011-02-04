require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  
  fixtures :all

  test "associations" do
    inv=investigations(:metabolomics_investigation)
    assert_equal projects(:sysmo_project),inv.project
    assert inv.studies.include?(studies(:metabolomics_study))    
  end

  test "sort by updated_at" do
    assert_equal Investigation.find(:all).sort_by {|i| i.updated_at.to_i * -1},Investigation.find(:all)
  end

  test "assays through association" do
    inv=investigations(:metabolomics_investigation)
    assays=inv.assays
    assert_not_nil assays
    assert assays.instance_of?(Array)
    assert_equal 3,assays.size
    assert assays.include?(assays(:metabolomics_assay))
    assert assays.include?(assays(:metabolomics_assay2))
    assert assays.include?(assays(:metabolomics_assay3))
  end  
  
  #the lib/sysmo/title_trimmer mixin should automatically trim the title :before_save
  test "title trimmed" do
    inv=Investigation.new(:title=>" Test",:project=>projects(:sysmo_project))
    inv.save!
    inv.reload
    assert_equal "Test",inv.title
  end
  
  test "validations" do
    
    inv=Investigation.new(:title=>"Test",:project=>projects(:sysmo_project))
    assert inv.valid?
    inv.title=""
    assert !inv.valid?
    inv.title=nil
    assert !inv.valid?

    inv.title="Test"
    inv.project=nil
    assert !inv.valid?

    inv.project=projects(:sysmo_project)
    assert inv.valid?

    #duplicate title not valid
    inv.title="Metabolomics Investigation"
    assert !inv.valid?

  end

  test "project member can delete with no study" do
    investigation=investigations(:investigation_with_no_study)
    assert investigation.can_delete?(users(:model_owner))
  end

  test "project member cant delete with study" do
    investigation=investigations(:metabolomics_investigation)
    assert !investigation.can_delete?(users(:model_owner))
  end

  test "non project member cant delete even with no study" do
    investigation=investigations(:investigation_with_no_study)
    assert !investigation.can_delete?(users(:aaron))
  end
  
  test "test uuid generated" do
    i = investigations(:metabolomics_investigation)
    assert_nil i.attributes["uuid"]
    i.save
    assert_not_nil i.attributes["uuid"]
  end 
  
  test "uuid doesn't change" do
    x = investigations(:metabolomics_investigation)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
