require 'test_helper'

class ProjectSubscriptionTest < ActiveSupport::TestCase
  def setup
    User.current_user = FactoryBot.create(:user)
    @proj = FactoryBot.create(:project)
    other_projects = [FactoryBot.create(:project),FactoryBot.create(:project),FactoryBot.create(:project)]
    person = FactoryBot.create(:person,project:@proj)
    other_projects.each{|p| person.add_to_project_and_institution(p,person.institutions.first)}
    @subscribables_in_proj = [FactoryBot.create(:subscribable, projects: [other_projects[0], @proj],contributor:person),
                              FactoryBot.create(:subscribable, projects: [@proj, other_projects[1], other_projects[2]],contributor:person),
                              FactoryBot.create(:subscribable, projects: [@proj],contributor:person)]
  end

  test 'subscribing to a project subscribes to subscribable items in the project' do
    ps = current_person.project_subscriptions.create project: @proj
    ProjectSubscriptionJob.perform_now(ps)
    assert @subscribables_in_proj.all?(&:subscribed?)
  end

  test 'new people subscribe to their projects by default when they are activated by admins' do
    # Default projects are NOT subscribed until new person is activated by admin with assigning projects and institutions to him/her
    new_person = FactoryBot.create(:brand_new_person)
    assert_equal new_person.project_subscriptions.map(&:project), []

    # when joining a project
    new_person.work_groups.create project: @proj, institution: FactoryBot.create(:institution)
    new_person.save
    assert_equal new_person.projects.sort_by(&:title), new_person.project_subscriptions.map(&:project).sort_by(&:title)
  end

  test 'subscribers to a project auto subscribe to new items in the project' do
    ps = current_person.project_subscriptions.create project: @proj
    ProjectSubscriptionJob.perform_now(ps)
    person = FactoryBot.create(:person,project:@proj)
    person.add_to_project_and_institution(FactoryBot.create(:project),person.institutions.first)
    s = nil
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      s = FactoryBot.create(:subscribable, projects: person.projects,contributor:person)
    end
    SetSubscriptionsForItemJob.perform_now(s, s.projects)

    assert s.subscribed?
  end

  test 'unsubscribers to a project auto unsubscribe to subscribable items in the project' do
    # subscribe
    ps = current_person.project_subscriptions.create project: @proj
    ProjectSubscriptionJob.perform_now(ps)
    assert @subscribables_in_proj.all?(&:subscribed?)

    # unsubscribe
    ps.destroy
    assert_nil ProjectSubscription.find_by_id(ps.id)
    @subscribables_in_proj.each(&:reload)
    assert !@subscribables_in_proj.all?(&:subscribed?)
  end

  test 'individual subscription frequency set by project subscription frequency' do
    ps = current_person.project_subscriptions.create project: @proj, frequency: 'daily'
    ProjectSubscriptionJob.perform_now(ps)
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:daily?)
    ps.frequency = 'monthly'
    ps.save!
    ProjectSubscriptionJob.perform_now(ps)
    @subscribables_in_proj.each(&:reload)
    assert @subscribables_in_proj.map(&:current_users_subscription).all?(&:monthly?)
  end

  test 'subscribers to a project auto subscribe to new publication in the project' do
    ps = current_person.project_subscriptions.create project: @proj
    ProjectSubscriptionJob.perform_now(ps)
    publication = nil
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      publication = FactoryBot.create(:publication, projects: [FactoryBot.create(:project), @proj])
    end
    SetSubscriptionsForItemJob.perform_now(publication, publication.projects)

    assert publication.subscribed?
  end

  private

  def current_person
    User.current_user.person
  end
end
