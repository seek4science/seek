require 'test_helper'

class SampleDataPersistJobTest < ActiveSupport::TestCase
  def setup
    create_sample_attribute_type
    @person = FactoryBot.create(:project_administrator)
    User.with_current_user(@person.user) do
	    @project_id = @person.projects.first.id

	    @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
		                             policy: FactoryBot.create(:private_policy), contributor: @person
	    refute @data_file.matching_sample_type?
	    assert_empty @data_file.possible_sample_types

	    @sample_type = SampleType.new title: 'from template', uploaded_template: true,
		                          project_ids: [@project_id], contributor: @person
	    @sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
	    @sample_type.build_attributes_from_template
	    # this is to force the full name to be 2 words, so that one row fails
	    @sample_type.sample_attributes.first.sample_attribute_type = FactoryBot.create(:full_name_sample_attribute_type)
	    @sample_type.sample_attributes[1].sample_attribute_type = FactoryBot.create(:datetime_sample_attribute_type)
	    @sample_type.save!
	end
  end

  test 'queue job' do
    assert_enqueued_jobs(1, only: SampleDataPersistJob) do
      SampleDataPersistJob.new(@data_file, @sample_type, @person.user).queue_job
    end
    @data_file.reload
    assert_equal Task::STATUS_QUEUED, @data_file.sample_persistence_task.status
  end

  test 'persists samples' do
    @data_file.policy = FactoryBot.create(:public_policy, permissions: [FactoryBot.create(:edit_permission)])
    disable_authorization_checks{@data_file.save!}
    assert_difference('Sample.count', 3) do
      assert_difference('Policy.count', 3) do
        assert_difference('Permission.count', 3) do
          assert_difference('ReindexingQueue.count', 3) do
            assert_difference('AuthLookupUpdateQueue.count', 3) do
              with_config_value(:auth_lookup_enabled, true) do # needed to test added to queue
                SampleDataPersistJob.perform_now(@data_file, @sample_type, @person.user)
              end
            end
          end
        end
      end
    end

    @data_file.reload

    assert_equal Task::STATUS_DONE, @data_file.sample_persistence_task.status

    assert_equal 3, @data_file.extracted_samples.count

    samples = @data_file.extracted_samples

    samples.each do |sample|
      assert_equal @sample_type, sample.sample_type
      assert_equal @person, sample.contributor
      assert_equal [@project_id], sample.project_ids
      assert_equal @person, sample.contributor
      assert_equal Policy::MANAGING, sample.policy.access_type
      assert_equal 1, sample.policy.permissions.count
      assert_equal Policy::EDITING, sample.policy.permissions.first.access_type
    end

    #check the policy and permissions are all uniq and not referencing each other
    refute_equal @data_file.policy_id, samples.first.policy_id
    policy_ids = samples.collect { |s| s.policy.id }
    permission_ids = samples.collect { |s| s.policy.permissions.first.id }
    assert_equal 3, policy_ids.count
    assert_equal policy_ids, policy_ids.uniq
    assert_equal 3, permission_ids.count
    assert_equal permission_ids, permission_ids.uniq
  end

  test 'persists samples and associate with assay' do
    assay_asset1 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::INCOMING,
                                         assay: FactoryBot.create(:assay, contributor: @person))
    assay_asset2 = FactoryBot.create(:assay_asset, asset: @data_file, direction: AssayAsset::Direction::OUTGOING,
                                         assay: FactoryBot.create(:assay, contributor: @person))

    assert_difference('AssayAsset.count', 3) do
      assert_difference('Sample.count', 3) do
        SampleDataPersistJob.perform_now(@data_file, @sample_type, @person.user, assay_ids: [assay_asset1.assay_id])
      end
    end

    @data_file.reload
    @data_file.extracted_samples.each do |sample|
      assert_equal [assay_asset1.assay], sample.assays
      assert_equal assay_asset1.direction, sample.assay_assets.first.direction
    end
  end

  test 'persists samples linked to private samples' do
    person = FactoryBot.create(:person)
    template_data_file = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:linked_samples_with_patient_content_blob))
    sample_type = FactoryBot.create(:linked_sample_type, title: 'Parent Sample Type', contributor: person)
    sample_type.sample_attributes.detect { |attr| attr.title == 'title' }.update_column(:template_column_index, 1)
    sample_type.sample_attributes.detect { |attr| attr.title == 'patient' }.update_column(:template_column_index, 2)
    FactoryBot.create(:linked_samples_with_patient_content_blob, asset: sample_type)
    sample_type.reload

    child_sample_type = sample_type.sample_attributes.last.linked_sample_type

    child_sample1 = Sample.create(sample_type: child_sample_type, contributor: person, projects: person.projects, data: { 'full name': 'Patient One', 'age': 20 }, policy: FactoryBot.create(:private_policy))
    child_sample2 = Sample.create(sample_type: child_sample_type, contributor: person, projects: person.projects, data: { 'full name': 'Patient Two', 'age': 20 }, policy: FactoryBot.create(:private_policy))

    assert sample_type.valid?
    refute_nil sample_type.content_blob

    assert child_sample1.valid?
    assert_equal 'Patient One', child_sample1.title
    refute child_sample1.can_view?
    assert child_sample2.valid?
    assert_equal 'Patient Two', child_sample2.title
    refute child_sample2.can_view?

    assert_includes template_data_file.possible_sample_types(person.user), sample_type
    assert_equal 2, template_data_file.extract_samples(sample_type, false, false).count

    assert_difference('Sample.count', 2) do
      SampleDataPersistJob.perform_now(template_data_file, sample_type, person.user)
    end

  end

  test 'records exception' do
    class FailingSampleDataPersistJob < SampleDataPersistJob
      def perform(data_file, sample_type, user, assay_ids: nil)
        raise 'critical error'
      end
    end

    FailingSampleDataPersistJob.perform_now(@data_file, @sample_type, @person.user)

    task = @data_file.sample_persistence_task
    assert task.failed?
    refute_nil task.exception

    # contains message and backtrace
    assert_match /critical error/, task.exception
    assert_match /block in perform_now/, task.exception
    assert_match /activejob/, task.exception

  end
end
