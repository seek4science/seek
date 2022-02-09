require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper
  
  test "Should return the dynamic table columns and rows" do
    person = Factory(:person)
    project = person.projects.first

    User.with_current_user(person.user) do
      inv = Factory(:investigation, projects: [project], contributor:person)

      sample_A1 = Factory(:max_sample)
      type_A = sample_A1.sample_type
      sample_A2 = Factory(:max_sample, sample_type: type_A)
      sample_A3 = Factory(:max_sample, sample_type: type_A)

      type_B = Factory(:multi_linked_sample_type, project_ids: [project.id])
      type_B.sample_attributes.last.linked_sample_type = type_A
      type_B.save!

      sample_B1 = Sample.new(sample_type: type_B, project_ids: [project.id])
      sample_B1.set_attribute_value(:title, 'sample_B1')
      sample_B1.set_attribute_value(:patient, [sample_A1.id])
      disable_authorization_checks { sample_B1.save! }

      sample_B2 = Sample.new(sample_type: type_B, project_ids: [project.id])
      sample_B2.set_attribute_value(:title, 'sample_B2')
      sample_B2.set_attribute_value(:patient, [sample_A2.id])
      disable_authorization_checks { sample_B2.save! }

      type_C = Factory(:multi_linked_sample_type, project_ids: [project.id])
      type_C.sample_attributes.last.linked_sample_type = type_B
      type_C.save!

      sample_C1 = Sample.new(sample_type: type_C, project_ids: [project.id])
      sample_C1.set_attribute_value(:title, 'sample_C1')
      sample_C1.set_attribute_value(:patient, [sample_B1.id])
      disable_authorization_checks { sample_C1.save! }

      study = Factory(:study, investigation: inv, contributor: person, sample_types: [type_A, type_B])

      dt = dt_aggregated(study)
      columns_count = study.sample_types.reduce(0) {|s,n| s + n.sample_attributes.length }

      assert_equal type_A.samples.length , dt[:rows].length
      assert_equal columns_count , dt[:columns].length
      dt[:rows].each {|r| assert_equal columns_count, r.length}

      assert_equal false, dt[:rows][0].any? { |x| x == "" }
      assert_equal false, dt[:rows][1].any? { |x| x == "" }
      assert_equal true, dt[:rows][2].any? { |x| x == "" }

    end

    # |-------------------------------------------------------------------------|
    # |         type_A         |         type_B         |         type_C        |
    # |------------------------|------------------------|-----------------------|
    # |  (status)(id)sample_A1 | (status)(id)sample_B1  | (status)(id)sample_C1 |
    # |  (status)(id)sample_A2 | (status)(id)sample_B2  | x                     |
    # |  (status)(id)sample_A3 | x                      | x                     |
    # |-------------------------------------------------------------------------|

    # TODO test when there is(are) 1(more) assay(s)
    # TODO test with no sample
    
  end

end
