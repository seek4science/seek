require "test_helper"

class SampleTest < ActiveSupport::TestCase


  # Called before every test method runs. Can be used
  # to set up fixture information.
  test "validation" do

    s = Factory :sample,:title =>"TestSample",:policy=>Factory(:private_policy)
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
      assert Factory.build(:sample, :projects => [],:policy=>Factory(:private_policy)).valid?
    end

    as_not_virtualliver do
      s.reload
      s.donation_date=nil
      assert s.valid?
      #for projects, it doesnt work by doing s.projects=[]
      assert !Factory.build(:sample, :projects => [],:policy=>Factory(:private_policy)).valid?
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
      sample.data_files << data_file
      sop = Factory :sop, :contributor => User.current_user
      sample.sops << sop
      assert sample.valid?
      assert sample.save
      assert_equal 1, sample.data_files.count
      assert_equal data_file, sample.data_files.first
      assert_equal 1, sample.data_file_versions.count
      assert_equal data_file.latest_version, sample.data_file_versions.first

      assert_equal 1, sample.sops.count
      assert_equal sop, sample.sops.first
      assert_equal 1, sample.sop_versions.count
      assert_equal sop.latest_version, sample.sop_versions.first
    end
  end

  test "related sops and data_files" do
    User.with_current_user Factory(:user) do
      sample = Factory :sample, :contributor => User.current_user
      data_file = Factory :data_file, :contributor => User.current_user
      sample.data_files << data_file
      sop = Factory :sop, :contributor => User.current_user
      sample.sops << sop
      assert sample.save

      sample.reload

      assert_equal [sop], sample.sops
      assert_equal [data_file], sample.data_files
    end
  end

  test "associated treatments" do
    treatment = Factory(:treatment)
    refute_nil treatment.sample
    sample = treatment.sample
    treatment2 = Factory(:treatment,:sample=>sample)
    sample.reload
    assert_equal 2,sample.treatments.size
    assert_include sample.treatments,treatment
    assert_include sample.treatments,treatment2

    #dependent destroy
    assert_difference('Treatment.count',-2) do
      assert_difference('Sample.count',-1) do
        disable_authorization_checks do
          sample.destroy
        end
      end
    end
    assert_nil Treatment.find_by_id(treatment.id)
    assert_nil Treatment.find_by_id(treatment2.id)
  end

end
