require "test_helper"

class SampleTest < ActiveSupport::TestCase


  # Called before every test method runs. Can be used
  # to set up fixture information.
  test "validation" do

    s = Factory :sample,:title =>"TestSample"
    assert s.valid?

    s.title= nil
    assert !s.valid?

    s.title=""
    assert !s.valid?

    #test uniqness of title
    s.reload
    assert !Factory.build(:sample,:title =>"TestSample").save

    s.lab_internal_number=nil
    assert !s.valid?

    if Seek::Config.is_virtualliver
      s.reload
      s.donation_date=nil
      assert !s.valid?
    end

    #s.reload
    #s.strains=[]
    #assert !s.valid?
  end

end
