require 'test_helper'

class SamplesBatchDeleteJobTest < ActiveSupport::TestCase

  test 'perform' do
    person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:simple_sample_type)
    samples = FactoryBot.create_list(:sample, 3, contributor: person, sample_type: sample_type)

    # to check it handles no permission
    refute samples.first.can_delete?

    assert_difference('Sample.count', -3 ) do
      assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample_type, false]) do
        assert_enqueued_jobs(1, only: SampleTypeUpdateJob) do
          assert_enqueued_with(job: AuthLookupDeleteJob, args: ['Sample', samples.first.id]) do
            assert_enqueued_jobs(3, only: AuthLookupDeleteJob) do
              SamplesBatchDeleteJob.perform_now(samples.collect(&:id))
            end
          end
        end
      end
    end

  end

  test 'perform handles non existent ids' do
    id = (Sample.maximum(:id) || 0) + 1
    assert_empty Sample.where(id: id)

    assert_nothing_raised do
      assert_no_difference('Sample.count' ) do
        SamplesBatchDeleteJob.perform_now([id])
      end
    end

  end

  test 'mixture of sample types' do
    person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type2 = FactoryBot.create(:simple_sample_type)
    samples = [FactoryBot.create(:sample, contributor: person, sample_type: sample_type), FactoryBot.create(:sample, contributor: person, sample_type: sample_type2)]

    assert_difference('Sample.count', -2 ) do
      assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample_type, false]) do
        assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample_type2, false]) do
          assert_enqueued_jobs(2, only: SampleTypeUpdateJob) do
            SamplesBatchDeleteJob.perform_now(samples.collect(&:id))
          end
        end
      end
    end
  end

end