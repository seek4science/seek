require 'test_helper'
class ProjectHierarchiesTest < ActiveSupport::TestCase
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users,  :publications, :assets, :organisms

  def setup
    User.current_user = Factory(:user)
    @proj = Factory(:project)
    @subscribables_in_proj = [Factory(:subscribable, :projects => [Factory(:project), @proj]), Factory(:subscribable, :projects => [@proj, Factory(:project), Factory(:project)]), Factory(:subscribable, :projects => [@proj])]
  end

  if Project.is_hierarchical?

    test "person's projects include direct projects and parent projects" do
      parent_proj = Factory :project
      proj = Factory :project, :parent_id => parent_proj.id
      p = Factory(:brand_new_person, :work_groups => [Factory(:work_group, :project => proj)])
      assert_equal [parent_proj, proj].map(&:id).sort, p.projects.map(&:id).sort
    end


    test "default subscriptions to direct projects and parent projects when admins assign projects" do

    end
    test 'people subscribe to their projects and parent projects by default' do
      #when created without a project
      person = Factory(:brand_new_person)

      assert_equal person.project_subscriptions.map(&:project), []

      #when joining a project
      project = Factory :project, :parent => @proj
      person.work_groups.create :project => project, :institution => Factory(:institution)
      disable_authorization_checks do
        #save person in order to save built project subscriptions
        person.save!
      end
      person.reload
      assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)
      assert_equal true, person.project_subscriptions.map(&:project).include?(@proj)
    end

    test 'subscribing to a project subscribes ONLY direct subscribable items in this project rather than subscribes to those in its ancestors' do
      # when person edits his profile to subscribe new project, only items in that direct project are subscribed
      child_project = Factory :project, :parent => @proj
      ProjectSubscriptionJob.new(current_person.project_subscriptions.create(:project => child_project).id).perform
      assert !@subscribables_in_proj.all?(&:subscribed?)
    end

    test 'subscribers to a project auto subscribe to new items in its ancestors' do
      child_project = Factory :project, :parent => @proj
      @proj.reload

      assert_equal @proj, child_project.parent

      ps = current_person.project_subscriptions.create :project => child_project
      ProjectSubscriptionJob.new(ps.id).perform

      s = Factory(:subscribable, :projects => [@proj], :title => "ancestor autosub test")
      assert SetSubscriptionsForItemJob.exists?(s.class.name, s.id, s.projects_and_descendants.map(&:id))

      SetSubscriptionsForItemJob.new(s.class.name, s.id, s.projects_and_descendants.collect(&:id)).perform

      s.reload
      assert s.subscribed?
    end

    test 'when the project tree updates, people are subscribed to items in the new parent of the projects they are subscribed to' do
      child_project = Factory :project
      current_person.project_subscriptions.create :project => child_project
      child_project.reload
      assert !child_project.project_subscriptions.map(&:person).empty?
      disable_authorization_checks do
        child_project.parent = @proj
        child_project.save!
      end
      @subscribables_in_proj.each &:reload
      assert @subscribables_in_proj.all?(&:subscribed?)
    end

    test "set parent" do
      parent_proj = Factory(:project, :title => "test parent")
      proj = Factory(:project, :parent_id => parent_proj.id)
      assert_equal proj.parent, parent_proj
      assert_equal true, parent_proj.descendants.include?(proj)
      parent_proj_changed = Factory(:project, :title => "changed test parent")
      proj.parent = parent_proj_changed
      proj.save!

      assert_equal "changed test parent", proj.parent.name

    end

    test "parent project have institutions of children" do
      institutions = [Factory(:institution), Factory(:institution)]
      parent_proj = Factory :project, :name => "parent proj"
      project = Factory :project, :parent => parent_proj
      project.institutions = institutions
      project.save!

      institutions.each do |ins|
        assert_equal true, parent_proj.institutions.include?(ins)
      end
    end

    test "related resource to parent project" do
      parent_proj = Factory :project
      proj = Factory :project, :parent => parent_proj

      Project::RELATED_RESOURCE_TYPES.each do |type|
        proj.send "#{type.underscore.pluralize}=".to_sym, [Factory(type.underscore.to_sym)] unless ["Study", "Assay"].include?(type)

        proj.send("#{type.underscore.pluralize}".to_sym).each do |resource|
          assert_equal true, parent_proj.send("related_#{type.underscore.pluralize}".to_sym).include?(resource)
        end
      end
    end


  end


  private

  def descendants_and_ancestors_are_consistent
    Project.all.each do |p|
      assert_equal p.ancestors, p.calculate_ancestors
      assert_equal p.descendants, get_descendants_recursively(p)
    end
  end

  def get_descendants_recursively project
    children = Project.find_all_by_parent_id project.id
    children + children.inject([]) { |acc, v| acc + get_descendants_recursively(v) }
  end

  def current_person
    User.current_user.person
  end
end