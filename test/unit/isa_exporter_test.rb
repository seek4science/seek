require 'test_helper'

class IsaExporterTest < ActionController::TestCase
  test 'find sample origin' do
    controller = IsaExporter::Exporter.new FactoryBot.create(:investigation)
    project = FactoryBot.create(:project)

    type_1 = FactoryBot.create(:simple_sample_type, project_ids: [project.id])
    type_2 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_2.sample_attributes.last.linked_sample_type = type_1
    type_2.save!

    type_3 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_3.sample_attributes.last.linked_sample_type = type_2
    type_3.save!

    type_4 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_4.sample_attributes.last.linked_sample_type = type_3
    type_4.save!

    # Create Samples
    parent =
      FactoryBot.create :sample,
              title: 'PARENT 1',
              sample_type: type_1,
              project_ids: [project.id],
              data: {
          the_title: 'PARENT 1'
              }

    child_1 = Sample.new(sample_type: type_2, project_ids: [project.id])
    child_1.set_attribute_value(:patient, [parent.id])
    child_1.set_attribute_value(:title, 'CHILD 1')
    child_1.save!

    child_2 = Sample.new(sample_type: type_3, project_ids: [project.id])
    child_2.set_attribute_value(:patient, [child_1.id])
    child_2.set_attribute_value(:title, 'CHILD 2')
    child_2.save!

    child_3 = Sample.new(sample_type: type_4, project_ids: [project.id])
    child_3.set_attribute_value(:patient, [child_2.id])
    child_3.set_attribute_value(:title, 'CHILD 3')
    child_3.save!

    assert_equal [parent.id], controller.send(:find_sample_origin, [child_1], 0)
    assert_equal [parent.id], controller.send(:find_sample_origin, [child_2], 0)
    assert_equal [parent.id], controller.send(:find_sample_origin, [child_3], 0)
    assert_equal [child_1.id], controller.send(:find_sample_origin, [child_3], 1) # 0: source, 1: sample

    # Create another parent for child 1
    parent_2 =
      FactoryBot.create :sample,
              title: 'PARENT 2',
              sample_type: type_1,
              project_ids: [project.id],
              data: {
          the_title: 'PARENT 2'
              }
    disable_authorization_checks do
      child_1.set_attribute_value(:patient, [parent.id, parent_2.id])
      child_1.save!
    end

    child_3.reload
    assert_equal [parent.id, parent_2.id], controller.send(:find_sample_origin, [child_3], 0)
    assert_equal [child_1.id], controller.send(:find_sample_origin, [child_3], 1)

    # Create another parent for child 2
    child_2_another_parent = Sample.new(sample_type: type_2, project_ids: [project.id])
    child_2_another_parent.set_attribute_value(:patient, [parent.id])
    child_2_another_parent.set_attribute_value(:title, 'CHILD 2 ANOTHER PARENT')
    child_2_another_parent.save!

    disable_authorization_checks do
      child_2.set_attribute_value(:patient, [child_1.id, child_2_another_parent.id])
      child_2.save!
    end

    child_3.reload
    assert_equal [child_1.id, child_2_another_parent.id], controller.send(:find_sample_origin, [child_3], 1)
  end
end
