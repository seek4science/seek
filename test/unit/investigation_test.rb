require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  
  fixtures :all

  test "associations" do
    inv=investigations(:metabolomics_investigation)

    assert_equal projects(:sysmo_project),inv.project
    assert inv.studies.include?(studies(:metabolomics_study))
    
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
end
