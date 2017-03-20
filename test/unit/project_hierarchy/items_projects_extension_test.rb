require 'test_helper'
require 'project_hierarchy_test_helper'
class ItemsProjectsExtensionTest < ActiveSupport::TestCase
  include ProjectHierarchyTestHelper

  def setup
    skip_hierarchy_tests?
    @parent = Factory :project, title: 'New test project'
    @child1 = Factory :project, title: 'first child of new test project', parent_id: @parent.id
    @child2 = Factory :project, title: 'second child of new test project', parent_id: @parent.id
  end

  test 'projects and descendants' do
    class ItemWithProjects
      def projects
        Array(Project.where(title: 'New test project').first)
      end

      include Seek::ProjectHierarchies::ItemsProjectsExtension
    end

    assert_equal [@parent, @child1, @child2].sort, ItemWithProjects.new.projects_and_descendants.sort
  end

  test 'projects and ancestors' do
    class ItemWithProjects
      def projects
        Array(Project.where(title: 'first child of new test project').first)
      end

      include Seek::ProjectHierarchies::ItemsProjectsExtension
    end

    assert_equal [@parent, @child1].sort, ItemWithProjects.new.projects_and_ancestors.sort
  end
end
