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

    as_virtualliver do
      s.reload
      s.donation_date=nil
      assert !s.valid?
      #for projects, it doesnt work by doing s.projects=[]
      assert Factory.build(:sample, :projects => []).valid?
    end

    as_not_virtualliver do
      s.reload
      s.donation_date=nil
      assert s.valid?
      #for projects, it doesnt work by doing s.projects=[]
      assert !Factory.build(:sample, :projects => []).valid?
    end

    s.reload
    s.specimen=nil
    assert !s.valid?
  end

  test "to rdf" do
    object = Factory :sample, :contributor=>Factory(:person),:assay_ids=>[Factory(:assay).id], :provider_id=>"r2d2",
                     :sampling_date=>1.day.ago, :donation_date=>2.days.ago, :specimen=>Factory(:specimen)

    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/samples/#{object.id}"), reader.statements.first.subject
    end

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
