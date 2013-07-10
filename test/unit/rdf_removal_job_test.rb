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
      RdfRemovalJob.create_job item
    end
    job = Delayed::Job.last
    assert_equal 2,job.priority
  end

  test "priority is higher than generation" do
    item = Factory(:assay)
    removal_job = RdfRemovalJob.create_job item
    generate_job = RdfGenerationJob.create_job item
    assert removal_job.priority < generate_job.priority
  end

  test "perform" do
    item = Factory(:assay)
    item.save_rdf
    path = File.join(Rails.root,"tmp/testing-filestore/tmp/rdf/private","Assay-#{item.id}.rdf")
    assert File.exists?(path)
    removal_job = RdfRemovalJob.new "Assay",item.id
    removal_job.perform
    assert !File.exists?(path)
  end
end