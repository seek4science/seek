require 'test_helper'

class DynamicTableHelperTest < ActionView::TestCase
  include AuthenticatedTestHelper
  
  test "Should return the dynamic table columns and rows" do
    person = Factory(:person)
    project = person.projects.first

    User.with_current_user(person.user) do
      inv = Factory(:investigation, projects: [project], contributor:person)

      sample1 = Factory(:max_sample)
      sample1_1 = Factory(:max_sample, sample_type: sample1.sample_type)
      sample1_2 = Factory(:max_sample, sample_type: sample1.sample_type)

      type2 = Factory(:multi_linked_sample_type, project_ids: [project.id])
      type2.sample_attributes.last.linked_sample_type = sample1.sample_type
      type2.save!

      sample2 = Sample.new(sample_type: type2, project_ids: [project.id])
      sample2.set_attribute_value(:title, 'sample2')
      sample2.set_attribute_value(:patient, [sample1.id])
      disable_authorization_checks { sample2.save! }

      sample2_1 = Sample.new(sample_type: type2, project_ids: [project.id])
      sample2_1.set_attribute_value(:title, 'sample2_1')
      sample2_1.set_attribute_value(:patient, [sample1_1.id])
      disable_authorization_checks { sample2_1.save! }

      type3 = Factory(:multi_linked_sample_type, project_ids: [project.id])
      type3.sample_attributes.last.linked_sample_type = type2
      type3.save!

      sample3 = Sample.new(sample_type: type3, project_ids: [project.id])
      sample3.set_attribute_value(:title, 'sample3')
      sample3.set_attribute_value(:patient, [sample2.id])
      disable_authorization_checks { sample3.save! }

      study = Factory(:study, investigation: inv, contributor:person)
      study.sample_types = [sample1.sample_type, type2]
      study.save!

      types = [sample1.sample_type, type2, type3]
      for limit in 2..3 do
        custom_attributes_count = limit * 2
        dt = dt_data(types, limit)
        assert_equal sample1.sample_type.samples.length , dt[:rows].length

        columns_count = types.slice(0,limit).map{|s| s.sample_attributes}.flatten.length + custom_attributes_count

        assert_equal columns_count , dt[:columns].length
        dt[:rows].each {|r| assert_equal columns_count, r.length}
      end

      assert_equal false, dt[:rows][0].any? { |x| x == "" }
      assert_equal true, dt[:rows][1].any? { |x| x == "" }
      assert_equal true, dt[:rows][2].any? { |x| x == "" }

      dt = dt_data(types, 1)
      puts dt[:columns].inspect
      puts dt[:rows][0]
    end

    # |-------------------------------------------------------------------------|
    # |         ST1            |          ST2           |           ST3         |
    # |------------------------|------------------------|-----------------------|
    # |  (status)(id)sample1   | (status)(id)sample2    | (status)(id)sample3   |
    # |  (status)(id)sample1_1 | (status)(id)sample2_1  | x                     |
    # |  (status)(id)sample1_2 | x                      | x                     |
    # |-------------------------------------------------------------------------|

  end

end
