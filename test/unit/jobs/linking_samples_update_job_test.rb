require 'test_helper'

class LinkingSamplesUpdateJobTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    create_linked_samples
  end

  test 'perform' do
    sample = Sample.first
    sample.set_attribute_value('full name', 'Ali Mohammadi')
    disable_authorization_checks { sample.save! }

    LinkingSamplesUpdateJob.perform_now(sample)

    sample.linking_samples.each do |s|
      assert_equal 'Ali Mohammadi', s.get_attribute_value(:patient)[0][:title]
    end
  end

  test 'only trigger further jobs if the metadata changes' do
    sample = Sample.first
    sample.set_attribute_value('full name', 'Ali Mohammadi')
    disable_authorization_checks { sample.save! }
    assert_enqueued_jobs 2, only: LinkingSamplesUpdateJob do
      LinkingSamplesUpdateJob.perform_now(sample)
    end

    sample.set_attribute_value('full name', 'Ali Mohammadi')
    disable_authorization_checks { sample.save! }
    assert_enqueued_jobs 0, only: LinkingSamplesUpdateJob do
      LinkingSamplesUpdateJob.perform_now(sample)
    end

    sample.set_attribute_value('full name', 'Fred Flintstone')
    disable_authorization_checks { sample.save! }
    assert_enqueued_jobs 2, only: LinkingSamplesUpdateJob do
      LinkingSamplesUpdateJob.perform_now(sample)
    end
  end


  def create_linked_samples

    project = @person.projects.first

    main_sample = FactoryBot.create(:patient_sample)
    sample_type = main_sample.sample_type

    another_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    another_sample_type.sample_attributes.last.linked_sample_type = sample_type
    another_sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'age',
                                                              sample_attribute_type: FactoryBot.create(:age_sample_attribute_type), required: false)
    another_sample_type.save!
    disable_authorization_checks do
      Sample.create!(sample_type: another_sample_type, project_ids: [project.id],
                     data: { title: 'linked_sample1', patient: [main_sample.id], age: 42 })

      s2 = Sample.create!(sample_type: another_sample_type, project_ids: [project.id],
                     data: { title: 'linked_sample2', patient: [main_sample.id], age: 43 })
      # Muddle the order of the properties in the JSON metadata
      s2.update_column(:json_metadata, JSON.parse(s2.json_metadata).slice('patient', 'age', 'title').to_json)
    end
  end

end
