require 'test_helper'

class SampleTypeUpdateJobTest < ActiveSupport::TestCase
  def setup
    SampleType.skip_callback(:save, :after, :queue_sample_type_update_job)
    @sample_type = Factory(:simple_sample_type)
    SampleType.set_callback(:save, :after, :queue_sample_type_update_job)
  end

  test 'perform' do
    type = sample_type_with_samples
    sample = type.samples.first
    updated_at = sample.updated_at
    assert_equal 'Fred Blogs', sample.title
    assert_equal 'M12 9LL', sample.get_attribute_value(:postcode)
    type.sample_attributes.detect { |t| t.title == 'full name' }.is_title = false
    type.sample_attributes.detect { |t| t.title == 'postcode' }.is_title = true
    disable_authorization_checks { type.save! }

    travel_to(Time.now + 1.minute) do
      assert_no_enqueued_jobs(only: SampleTypeUpdateJob) do # a new job shouldn't be created by the sample.save
        SampleTypeUpdateJob.perform_now(type, true)
      end
    end
    sample.reload
    assert_equal 'M12 9LL', sample.title
    # timestamps shouldn't change
    assert_equal updated_at, sample.updated_at
  end

  test 'perform without refresh' do
    type = sample_type_with_samples
    sample = type.samples.first
    updated_at = sample.updated_at
    assert_equal 'Fred Blogs', sample.title
    assert_equal 'M12 9LL', sample.get_attribute_value(:postcode)
    type.sample_attributes.detect { |t| t.title == 'full name' }.is_title = false
    type.sample_attributes.detect { |t| t.title == 'postcode' }.is_title = true
    disable_authorization_checks { type.save! }
    travel_to(Time.now + 1.minute) do
      SampleTypeUpdateJob.perform_now(type, false)
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
      sample.set_attribute_value('full name', 'Fred Blogs')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.set_attribute_value(:address, 'Somewhere')
      sample.set_attribute_value(:postcode, 'M12 9LL')
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute_value('full name', 'Fred Jones')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.set_attribute_value(:postcode, 'M12 9LJ')
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute_value('full name', 'Fred Smith')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.set_attribute_value(:address, 'Somewhere else')
      sample.set_attribute_value(:postcode, 'M12 9LA')
      sample.save!

      sample_type
    end

    sample_type.reload
    assert_equal 3, sample_type.samples.count

    sample_type
  end
end
