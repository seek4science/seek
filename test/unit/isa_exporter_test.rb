require "test_helper"

class IsaExporterTest < ActionController::TestCase
  fixtures :all
  include ActionView::Helpers::SanitizeHelper

  test "find sample origin" do
	controller = IsaExporter::Exporter.new Factory(:investigation)

	project = Factory(:project)
	
	# Create 4 sample types and link them
	type_1 = Factory(:multi_linked_sample_type, project_ids: [project.id])
	type_2 = Factory(:multi_linked_sample_type, project_ids: [project.id])
	type_3 = Factory(:multi_linked_sample_type, project_ids: [project.id])
	type_4 = Factory(:simple_sample_type, project_ids: [project.id])

	type_1.sample_attributes.last.linked_sample_type = type_2
   type_1.save!

	type_2.sample_attributes.last.linked_sample_type = type_3
   type_2.save!

	type_3.sample_attributes.last.linked_sample_type = type_4
   type_3.save!
	
	# Create Samples
	child_3 = Factory :sample, title: 'CHILD 3', sample_type: type_4, project_ids: [project.id], data: { the_title: 'CHILD 3' }

	child_2 = Sample.new(sample_type: type_3, project_ids: [project.id])
	child_2.set_attribute_value(:patient, [child_3.id])
	child_2.set_attribute_value(:title, 'CHILD 2')
	child_2.save!

	child_1 = Sample.new(sample_type: type_2, project_ids: [project.id])
	child_1.set_attribute_value(:patient, [child_2.id])
	child_1.set_attribute_value(:title, 'CHILD 1')
	child_1.save!

	parent = Sample.new(sample_type: type_1, project_ids: [project.id])
	parent.set_attribute_value(:patient, [child_1.id])
	parent.set_attribute_value(:title, 'PARENT')
	parent.save!
	

	assert_equal [parent.id], controller.send(:find_sample_origin, [child_1])
	assert_equal [parent.id], controller.send(:find_sample_origin, [child_2])
	assert_equal [parent.id], controller.send(:find_sample_origin, [child_3])

	# Create another parent for child 1
	parent_2 = Sample.new(sample_type: type_1, project_ids: [project.id])
	parent_2.set_attribute_value(:patient, [child_1.id])
	parent_2.set_attribute_value(:title, 'PARENT 2')
	parent_2.save!


	child_3.reload
	assert_equal [parent.id, parent_2.id], controller.send(:find_sample_origin, [child_3])
	
  end
end
