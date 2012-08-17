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

  test "sample-asset associations" do
    User.with_current_user Factory(:user) do
      sample = Factory :sample, :contributor => User.current_user
      data_file = Factory :data_file, :contributor => User.current_user
      sample.data_file_masters << data_file
      sop = Factory :sop, :contributor => User.current_user
      sample.sop_masters << sop
      assert sample.valid?
      assert sample.save
      assert_equal 1, sample.data_file_masters.count
      assert_equal data_file, sample.data_file_masters.first
      assert_equal 1, sample.data_files.count
      assert_equal data_file.latest_version, sample.data_files.first

      assert_equal 1, sample.sop_masters.count
      assert_equal sop, sample.sop_masters.first
      assert_equal 1, sample.sops.count
      assert_equal sop.latest_version, sample.sops.first
    end
  end

  test "related sops and data_files" do
    User.with_current_user Factory(:user) do
      sample = Factory :sample, :contributor => User.current_user
      data_file = Factory :data_file, :contributor => User.current_user
      sample.data_file_masters << data_file
      sop = Factory :sop, :contributor => User.current_user
      sample.sop_masters << sop
      assert sample.save

      assert_equal [sop], sample.related_sops
      assert_equal [data_file], sample.related_data_files
    end
  end
end
