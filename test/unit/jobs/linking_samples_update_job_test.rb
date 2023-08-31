require 'test_helper'

class LinkingSamplesUpdateJobTest < ActiveSupport::TestCase
  def setup
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

  def create_linked_samples
    person = FactoryBot.create(:person)
    project = person.projects.first

    main_sample = FactoryBot.create(:patient_sample)
    sample_type = main_sample.sample_type

    another_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    another_sample_type.sample_attributes.last.linked_sample_type = sample_type
    another_sample_type.save!

    linked_sample1 = Sample.new(sample_type: another_sample_type, project_ids: [project.id])
    linked_sample1.set_attribute_value(:title, 'linked_sample1')
    linked_sample1.set_attribute_value(:patient, [main_sample.id])
    disable_authorization_checks { linked_sample1.save! }

    linked_sample2 = Sample.new(sample_type: another_sample_type, project_ids: [project.id])
    linked_sample2.set_attribute_value(:title, 'linked_sample2')
    linked_sample2.set_attribute_value(:patient, [main_sample.id])
    disable_authorization_checks { linked_sample2.save! }
  end
end
