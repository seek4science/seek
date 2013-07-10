require 'test_helper'

class RdfGenerationJobTest  < ActiveSupport::TestCase

  def setup
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
  end

  test "create job" do
    item = Factory(:assay)
    assert_difference("Delayed::Job.count",1) do
      RdfGenerationJob.create_job item
    end
    job = Delayed::Job.last
    assert_equal 3,job.priority

  end

  test "perform" do
    item = Factory(:assay,:policy=>Factory(:public_policy))


    expected_rdf_file = File.join(Rails.root,"tmp/testing-filestore/tmp/rdf/public","Assay-#{item.id}.rdf")
    FileUtils.rm expected_rdf_file if File.exists?(expected_rdf_file)

    job = RdfGenerationJob.new "Assay",item.id
    job.perform

    assert File.exists?(expected_rdf_file)
    rdf=""
    open(expected_rdf_file) do |f|
      rdf = f.read
    end
    assert_equal item.to_rdf,rdf
    FileUtils.rm expected_rdf_file
    assert !File.exists?(expected_rdf_file)
  end
end