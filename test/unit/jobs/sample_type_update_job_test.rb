require 'test_helper'
require 'time_test_helper'

class SampleTypeUpdateJobTest < ActiveSupport::TestCase
  def setup
    SampleType.skip_callback(:save, :after, :queue_sample_type_update_job)
    @sample_type = Factory(:simple_sample_type)
    SampleType.set_callback(:save, :after, :queue_sample_type_update_job)
  end

  test 'exists' do
    SampleTypeUpdateJob.new(@sample_type).queue_job
    assert SampleTypeUpdateJob.new(@sample_type).exists?
  end

  test 'disallow duplicates' do
    assert_difference('Delayed::Job.count', 1) do
      SampleTypeUpdateJob.new(@sample_type).queue_job
    end

    assert_no_difference('Delayed::Job.count') do
      SampleTypeUpdateJob.new(@sample_type).queue_job
    end
  end

  test 'perform' do
    type = sample_type_with_samples
    sample = type.samples.first
    updated_at = sample.updated_at
    assert_equal 'Fred Blogs', sample.title
    assert_equal 'M12 9LL', sample.get_attribute(:postcode)
    type.sample_attributes.detect { |t| t.title == 'full name' }.is_title = false
    type.sample_attributes.detect { |t| t.title == 'postcode' }.is_title = true
    disable_authorization_checks { type.save! }

    Delayed::Job.destroy_all

    # check there is no existing job triggered from a sample.save
    refute SampleTypeUpdateJob.new(type, false).exists?

    job = SampleTypeUpdateJob.new(type)
    pretend_now_is(Time.now + 1.minute) do
      job.perform
    end
    sample.reload
    assert_equal 'M12 9LL', sample.title
    # timestamps shouldn't change
    assert_equal updated_at, sample.updated_at

    # a new job shouldn't be created by the sample.save
    refute SampleTypeUpdateJob.new(type, false).exists?
  end

  test 'perform without refresh' do
    type = sample_type_with_samples
    sample = type.samples.first
    updated_at = sample.updated_at
    assert_equal 'Fred Blogs', sample.title
    assert_equal 'M12 9LL', sample.get_attribute(:postcode)
    type.sample_attributes.detect { |t| t.title == 'full name' }.is_title = false
    type.sample_attributes.detect { |t| t.title == 'postcode' }.is_title = true
    disable_authorization_checks { type.save! }
    job = SampleTypeUpdateJob.new(type, false)
    pretend_now_is(Time.now + 1.minute) do
      job.perform
    end
    sample.reload
    assert_equal 'Fred Blogs', sample.title
    # timestamps shouldn't change
    assert_equal updated_at, sample.updated_at
  end

  def sample_type_with_samples
    person = Factory(:person)

    sample_type = User.with_current_user(person.user) do
      project = person.projects.first
      sample_type = Factory(:patient_sample_type, project_ids: [project.id])
      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute(:full_name, 'Fred Blogs')
      sample.set_attribute(:age, 22)
      sample.set_attribute(:weight, 12.2)
      sample.set_attribute(:address, 'Somewhere')
      sample.set_attribute(:postcode, 'M12 9LL')
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute(:full_name, 'Fred Jones')
      sample.set_attribute(:age, 22)
      sample.set_attribute(:weight, 12.2)
      sample.set_attribute(:postcode, 'M12 9LJ')
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute(:full_name, 'Fred Smith')
      sample.set_attribute(:age, 22)
      sample.set_attribute(:weight, 12.2)
      sample.set_attribute(:address, 'Somewhere else')
      sample.set_attribute(:postcode, 'M12 9LA')
      sample.save!

      sample_type
    end

    sample_type.reload
    assert_equal 3, sample_type.samples.count

    sample_type
  end
end
