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
    person.work_groups << Factory(:work_group, :project => @proj, :institution => Factory(:institution))
    person.save!
    person = Person.find(person.id)
    assert_equal person.projects.sort_by(&:title), person.project_subscriptions.map(&:project).sort_by(&:title)
  end

  test 'subscribers to a project auto subscribe to new items in the project' do
    ps = current_person.project_subscriptions.create :project => @proj
    ProjectSubscriptionJob.new(ps.id).perform
    s = Factory(:subscribable, :projects => [Factory(:project),@proj])
    assert SetSubscriptionsForItemJob.exists?(s.class.name, s.id, s.projects.collect(&:id))
    SetSubscriptionsForItemJob.new(s.class.name, s.id, s.projects.collect(&:id)).perform

    assert s.subscribed?
  end

  test 'unsubscribers to a project auto unsubscribe to subscribable items in the project' do
    #subscribe
    ps = current_person.project_subscriptions.create :project => @proj
    ProjectSubscriptionJob.new(ps.id).perform
    assert @subscribables_in_proj.all?(&:subscribed?)

    #unsubscribe
    ps.destroy
    assert_nil ProjectSubscription.find_by_id(ps.id)
    @subscribables_in_proj.each{|s| s.reload}
    assert !@subscribables_in_proj.all?(&:subscribed?)
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

  test 'subscribers to a project auto subscribe to new publication in the project' do
    ps = current_person.project_subscriptions.create :project => @proj
    ProjectSubscriptionJob.new(ps.id).perform
    publication = Factory(:publication, :projects => [Factory(:project),@proj])
    assert SetSubscriptionsForItemJob.exists?(publication.class.name, publication.id, publication.projects.collect(&:id))
    SetSubscriptionsForItemJob.new(publication.class.name, publication.id, publication.projects.collect(&:id)).perform

    assert publication.subscribed?
  end

  private

  def current_person
    User.current_user.person
  end

end