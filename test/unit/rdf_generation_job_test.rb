require 'test_helper'

class RdfGenerationJobTest  < ActiveSupport::TestCase

  def setup
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
  end

  test "rdf generation job created after save" do
    item = nil

    assert_difference("Delayed::Job.count",1) do
      item = Factory :project
    end

    Delayed::Job.delete_all #necessary, otherwise the next assert will fail since it won't create a new job if it already exists as pending

    assert_difference("Delayed::Job.count",1) do
      item.title="sdfhsdfkhsdfklsdf2"
      item.save!
    end
    item = Factory :model
    item.last_used_at=Time.now
    assert_no_difference("Delayed::Job.count") do
      item.save!
    end
  end

  test "create job" do
    item = Factory(:assay)

    Delayed::Job.delete_all

    assert_difference("Delayed::Job.count",1) do
      RdfGenerationJob.create_job item
    end
    job = Delayed::Job.last
    assert_equal 3,job.priority

  end

  test "exists" do
    project = Factory(:project)
    project2 = Factory(:project)

    Delayed::Job.delete_all

    assert !RdfGenerationJob.exists?(project,true)
    assert !RdfGenerationJob.exists?(project,false)

    Delayed::Job.enqueue RdfGenerationJob.new(project.class.name,project.id,true),:priority=>1,:run_at=>Time.now
    assert RdfGenerationJob.exists?(project,true)
    assert RdfGenerationJob.exists?(project,false), "should reports exists, because one alreayd exists with refresh_dependents true"
    assert !RdfGenerationJob.exists?(project2,true)
    assert !RdfGenerationJob.exists?(project2,false)

    Delayed::Job.enqueue RdfGenerationJob.new(project2.class.name,project2.id,false),:priority=>1,:run_at=>Time.now
    assert RdfGenerationJob.exists?(project2,false)
    assert !RdfGenerationJob.exists?(project2,true) ,"shouldn't reports exists, because one alreayd exists with refresh_dependents false, but this is true"

  end

  test "perform" do
    item = Factory(:assay,:policy=>Factory(:public_policy))


    expected_rdf_file = File.join(Rails.root,"tmp/testing-filestore/rdf/public","Assay-test-#{item.id}.rdf")
    assert_equal expected_rdf_file, item.rdf_storage_path
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