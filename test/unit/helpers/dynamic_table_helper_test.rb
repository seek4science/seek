require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper
  test "Should return the dynamic table columns and rows" do
    person = Factory(:person)
    project = person.projects.first

    User.with_current_user(person.user) do
      inv = Factory(:investigation, projects: [project], contributor: person)

      sample_a1 = Factory(:max_sample)
      type_a = sample_a1.sample_type
      sample_a2 = Factory(:max_sample, sample_type: type_a)
      sample_a3 = Factory(:max_sample, sample_type: type_a)

      type_b = Factory(:multi_linked_sample_type, project_ids: [project.id])
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

      type_c = Factory(:multi_linked_sample_type, project_ids: [project.id])
      type_c.sample_attributes.last.linked_sample_type = type_b
      type_c.save!

      sample_c1 = Sample.new(sample_type: type_c, project_ids: [project.id])
      sample_c1.set_attribute_value(:title, 'sample_c1')
      sample_c1.set_attribute_value(:patient, [sample_b1.id])
      disable_authorization_checks { sample_c1.save! }

      study = Factory(:study, investigation: inv, contributor: person, sample_types: [type_a, type_b])
			assay = Factory(:assay, study: study, contributor: person, sample_type: type_c)

      dt = dt_aggregated(study, true)
			# Each sample types' attributes length + the sample.id
      columns_count = study.sample_types[0].sample_attributes.length + 1
			columns_count += study.sample_types[1].sample_attributes.length + 1
			columns_count += assay.sample_type.sample_attributes.length + 1

      assert_equal type_a.samples.length, dt[:rows].length
      assert_equal columns_count, dt[:columns].length
      dt[:rows].each { |r| assert_equal columns_count, r.length }

      assert_equal false, (dt[:rows][0].any? { |x| x == '' })
      assert_equal true, (dt[:rows][1].any? { |x| x == '' })
      assert_equal true, (dt[:rows][2].any? { |x| x == '' })
    end

    # |-------------------------------------------------------------------------|
    # |         type_a         |         type_b         |         type_c        |
    # |------------------------|------------------------|-----------------------|
    # |  (status)(id)sample_a1 | (status)(id)sample_b1  | (status)(id)sample_c1 |
    # |  (status)(id)sample_a2 | (status)(id)sample_b2  | x                     |
    # |  (status)(id)sample_a3 | x                      | x                     |
    # |-------------------------------------------------------------------------|
  end
end
