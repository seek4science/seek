require 'test_helper'
#Authorization tests that are specific to public access
class ProjectSubscriptionTest < ActiveSupport::TestCase

  def setup
    User.current_user = Factory(:user)
    @proj = Factory(:project)
    @subscribables_in_proj = [Factory(:subscribable, :project => @proj), Factory(:subscribable, :project => @proj), Factory(:subscribable, :project => @proj)]
  end

  test 'subscribing to a project subscribes to subscribable items in the project' do
    current_person.project_subscriptions.create :project => @proj
    assert @subscribables_in_proj.all?(&:subscribed?)
  end

  test 'People subscribe to their projects by default' do
    #when created with a project
    person = Factory(:person, :group_memberships => [Factory(:group_membership)])
    assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)

    #when joining a project
    person.work_groups.create :project => @proj, :institution => Factory(:institution)
    assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)
  end

  test 'subscribers to a project auto subscribe to new items in the project' do
    current_person.project_subscriptions.create :project => @proj
    assert Factory(:subscribable, :project => @proj).subscribed?
  end

  test 'individual subscription frequency set by project subscription frequency' do
    ps = current_person.project_subscriptions.create :project => @proj, :frequency => 'daily'
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:daily?)
    ps.frequency = 'monthly'; ps.save!
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:monthly?)
  end

  private

  def current_person
    User.current_user.person
  end

end