require 'test_helper'

class IsaExporterTest < ActionController::TestCase
	test 'find sample origin' do
		# user = Factory :user
		# User.current_user = user

		controller = IsaExporter::Exporter.new Factory(:investigation)

		project = Factory(:project)

		# user.person.add_to_project_and_institution(project, project.institutions.first)

		type_1 = Factory(:simple_sample_type, project_ids: [project.id])
		type_2 = Factory(:multi_linked_sample_type, project_ids: [project.id])
		type_2.sample_attributes.last.linked_sample_type = type_1
		type_2.save!

		type_3 = Factory(:multi_linked_sample_type, project_ids: [project.id])
		type_3.sample_attributes.last.linked_sample_type = type_2
		type_3.save!

		type_4 = Factory(:multi_linked_sample_type, project_ids: [project.id])
		type_4.sample_attributes.last.linked_sample_type = type_3
		type_4.save!

		# Create Samples
		parent =
			Factory :sample,
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

		assert_equal [parent.id], controller.send(:find_sample_origin, [child_1])
		assert_equal [parent.id], controller.send(:find_sample_origin, [child_2])
		assert_equal [parent.id], controller.send(:find_sample_origin, [child_3])

		# Create another parent for child 1
		parent_2 =
			Factory :sample,
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
		assert_equal [parent.id, parent_2.id], controller.send(:find_sample_origin, [child_3])
	end
end
