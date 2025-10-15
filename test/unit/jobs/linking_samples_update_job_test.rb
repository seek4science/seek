require 'test_helper'

class LinkingSamplesUpdateJobTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    create_linked_samples
  end

  test 'perform' do
    @main_sample.set_attribute_value('full name', 'Ali Mohammadi')
    disable_authorization_checks { @main_sample.save! }

    LinkingSamplesUpdateJob.perform_now(@main_sample)

    @main_sample.linking_samples.each do |s|
      assert_equal 'Ali Mohammadi', s.get_attribute_value(:patient)[0][:title]
    end
  end

  test 'triggers job on title change' do
    @main_sample.set_attribute_value('full name', 'Ali Mohammadi')
    assert_enqueued_with(job: LinkingSamplesUpdateJob, args: [@main_sample]) do
      disable_authorization_checks { @main_sample.save! }
    end
  end

  test 'does not trigger job on other change' do
    @main_sample.set_attribute_value('age', 66)
    assert_enqueued_jobs 0, only: LinkingSamplesUpdateJob do
      disable_authorization_checks { @main_sample.save! }
    end
  end

  test 'does not recursively trigger jobs' do
    @main_sample.set_attribute_value('full name', 'Ali Mohammadi')
    disable_authorization_checks { @main_sample.save! }
    assert_enqueued_jobs 0, only: LinkingSamplesUpdateJob do
      LinkingSamplesUpdateJob.perform_now(@main_sample)
    end
  end

  def create_linked_samples
    project = @person.projects.first

    @main_sample = FactoryBot.create(:patient_sample)
    sample_type = @main_sample.sample_type

    another_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    another_sample_type.sample_attributes.last.linked_sample_type = sample_type
    another_sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'age',
                                                              sample_attribute_type: FactoryBot.create(:age_sample_attribute_type), required: false)
    another_sample_type.save!
    disable_authorization_checks do
      Sample.create!(sample_type: another_sample_type, project_ids: [project.id],
                     data: { title: 'linked_sample1', patient: [@main_sample.id], age: 42 })

      s2 = Sample.create!(sample_type: another_sample_type, project_ids: [project.id],
                     data: { title: 'linked_sample2', patient: [@main_sample.id], age: 43 })
      # Muddle the order of the properties in the JSON metadata
      s2.update_column(:json_metadata, JSON.parse(s2.json_metadata).slice('patient', 'age', 'title').to_json)
    end
  end

end
