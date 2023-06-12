require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper
  test 'Should return the dynamic table columns and rows' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    User.with_current_user(person.user) do
      inv = FactoryBot.create(:investigation, projects: [project], contributor: person)

      sample_a1 = FactoryBot.create(:patient_sample)
      type_a = sample_a1.sample_type
      sample_a2 = FactoryBot.create(:patient_sample, sample_type: type_a)
      sample_a3 = FactoryBot.create(:patient_sample, sample_type: type_a)

      type_b = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
      type_b.sample_attributes.last.linked_sample_type = type_a
      type_b.save!

      sample_b1 = Sample.new(sample_type: type_b, project_ids: [project.id])
      sample_b1.set_attribute_value(:title, 'sample_b1')
      sample_b1.set_attribute_value(:patient, [sample_a1.id])
      disable_authorization_checks { sample_b1.save! }

      sample_b2 = Sample.new(sample_type: type_b, project_ids: [project.id])
      sample_b2.set_attribute_value(:title, 'sample_b2')
      sample_b2.set_attribute_value(:patient, [sample_a2.id])
      disable_authorization_checks { sample_b2.save! }

      type_c = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
      type_c.sample_attributes.last.linked_sample_type = type_b
      type_c.save!

      sample_c1 = Sample.new(sample_type: type_c, project_ids: [project.id])
      sample_c1.set_attribute_value(:title, 'sample_c1')
      sample_c1.set_attribute_value(:patient, [sample_b1.id])
      disable_authorization_checks { sample_c1.save! }

      study = FactoryBot.create(:study, investigation: inv, contributor: person, sample_types: [type_a, type_b])
      assay = FactoryBot.create(:assay, study: study, contributor: person, sample_type: type_c, position: 1)

      # Query with the Study:
      # |-------------------------------------------------|
      # |         type_a         |         type_b         |
      # |------------------------|------------------------|
      # |  (status)(id)sample_a1 | (status)(id)sample_b1  |
      # |  (status)(id)sample_a2 | (status)(id)sample_b2  |
      # |  (status)(id)sample_a3 | x                      |
      # |-------------------------------------------------|

      dt = dt_aggregated(study)
      # Each sample types' attributes count + the sample.id
      columns_count = study.sample_types[0].sample_attributes.length + 2
      columns_count += study.sample_types[1].sample_attributes.length + 2

      assert_equal type_a.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
      assert_equal false, (dt[:rows][1].any? { |x| x == '' })
      assert_equal true, (dt[:rows][2].any? { |x| x == '' })

      # Query with the Assay:
      # |-----------------------|
      # |         type_c        |
      # |-----------------------|
      # | (status)(id)sample_c1 |
      # |-----------------------|

      dt = dt_aggregated(study, assay)
      # Each sample types' attributes count + the sample.id
      columns_count = assay.sample_type.sample_attributes.length + 2

      assert_equal type_c.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
    end
  end

  test 'Should return the sequence of sample_type links' do
    type1 = FactoryBot.create(:simple_sample_type)
    type2 = FactoryBot.create(:multi_linked_sample_type)
    type3 = FactoryBot.create(:multi_linked_sample_type)
    type2.sample_attributes.detect(&:seek_sample_multi?).linked_sample_type = type1
    type3.sample_attributes.detect(&:seek_sample_multi?).linked_sample_type = type2
    type2.save!
    type3.save!

    sequence = link_sequence(type3)
    assert_equal sequence, [type3, type2, type1]
  end
end
