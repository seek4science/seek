require 'test_helper'

class ProjectSubscriptionTest < ActiveSupport::TestCase

  def setup
    User.current_user = Factory(:user)
    @proj = Factory(:project)
    @subscribables_in_proj = [Factory(:subscribable, :projects => [Factory(:project),@proj]), Factory(:subscribable, :projects => [@proj,Factory(:project),Factory(:project)]), Factory(:subscribable, :projects => [@proj])]
  end

  test 'subscribing to a project subscribes to subscribable items in the project' do
    ps = current_person.project_subscriptions.create :project => @proj
    ProjectSubscriptionJob.new(ps.id).perform
    assert @subscribables_in_proj.all?(&:subscribed?)
  end

  test 'People subscribe to their projects by default' do
    #when created with a project
    person = Factory(:person, :group_memberships => [Factory(:group_membership)])
    assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)

    #when joining a project
    person.work_groups.create :project => @proj, :institution => Factory(:institution)
    person.reload
    assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)
  end

  test 'subscribers to a project auto subscribe to new items in the project' do
    ps = current_person.project_subscriptions.create :project => @proj
    ProjectSubscriptionJob.new(ps.id).perform
    assert Factory(:subscribable, :projects => [Factory(:project),@proj]).subscribed?
  end

  test 'individual subscription frequency set by project subscription frequency' do
    ps = current_person.project_subscriptions.create :project => @proj, :frequency => 'daily'
    ProjectSubscriptionJob.new(ps.id).perform
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:daily?)
    ps.frequency = 'monthly'
    ps.save!
    ProjectSubscriptionJob.new(ps.id).perform
    @subscribables_in_proj.each(&:reload)
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:monthly?)
  end

  test 'subscribing to a project auto subscribes to subscribable items in its ancestors' do
    child_project = Factory :project, :parent => @proj
    ProjectSubscriptionJob.new(current_person.project_subscriptions.create(:project => child_project).id).perform
    assert @subscribables_in_proj.all?(&:subscribed?)
  end

  test 'subscribers to a project auto subscribe to new items in its ancestors' do
    child_project = Factory :project, :parent => @proj
    @proj.reload
    current_person.project_subscriptions.create(:project => child_project).id
    assert Factory(:subscribable, :projects => [@proj], :title => "ancestor autosub test").subscribed?
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

  private

  def descendants_and_ancestors_are_consistent
    Project.all.each do |p|
      assert_equal p.ancestors, p.calculate_ancestors
      assert_equal p.descendants, get_descendants_recursively(p)
    end
  end

  def get_descendants_recursively project
    children = Project.find_all_by_parent_id project.id
    children + children.inject([]) {|acc, v| acc + get_descendants_recursively(v)}
  end

  def current_person
    User.current_user.person
  end

end