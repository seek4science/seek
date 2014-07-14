require 'test_helper'
class ProjectHierarchiesTest < ActionController::IntegrationTest
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users, :publications, :assets, :organisms

  def setup

    skip("tests are skipped as projects are NOT hierarchical") unless Seek::Config.project_hierarchy_enabled

    User.current_user = Factory(:user, :login => 'test')
    #test actions in controller with User.current_user not nil
    post '/session', :login => 'test', :password => 'blah'


    @proj = Factory(:project)
    @subscribables_in_proj = [Factory(:subscribable, :projects => [Factory(:project), @proj]), Factory(:subscribable, :projects => [@proj, Factory(:project), Factory(:project)]), Factory(:subscribable, :projects => [@proj])]

    @person = Factory(:brand_new_person)
    #add 2 work_groups directly
    @proj_child1 = Factory :project, :parent => @proj
    @proj_child2 = Factory :project, :parent => @proj
    @proj.reload
    @person.work_groups.create :project => @proj_child1, :institution => Factory(:institution)
    @person.work_groups.create :project => @proj_child2, :institution => Factory(:institution)
    disable_authorization_checks do
      #save person in order to save built project subscriptions
      @person.save!
    end
    @person.reload

  end



  test "rails 3 bug: before_add is not fired before the record is saved on `has_many :through` associations" do
    # no problem in the application, as work_groups are added directly with UI
    #problem in test is caused that the group_memberships instead of work_groups are assigned to person when created

    #BUG: `before_add` callbacks are fired before the record is saved on
    #`has_and_belongs_to_many` associations *and* on `has_many :through`
    #associations.  Before this change, `before_add` callbacks would be fired
    #before the record was saved on `has_and_belongs_to_many` associations, but
    #*not* on `has_many :through` associations.

    #this is solved in Rails 4 https://github.com/rails/rails/commit/b1656fa6305a5c8237027ab8165d7292751c0e86
    # add work groups via adding group_memberships which is the join table of people and work_groups
    #results: work_groups are added but before_add callbacks are not fired
    person = Factory(:person)

    #'before_add' callback of 'work_groups' association is not fired.
    #project subscriptions should be created before person is saved but not
    assert_equal true, person.project_subscriptions.empty?

    #when created without a project
    person = Factory(:brand_new_person)
    assert_equal 0, person.project_subscriptions.count

    #add 2 work_groups directly
    project1 = Factory :project, :parent => @proj
    project2 = Factory :project, :parent => @proj
    person.work_groups.create :project => project1, :institution => Factory(:institution)
    person.work_groups.create :project => project2, :institution => Factory(:institution)
    disable_authorization_checks do
      #save person in order to save built project subscriptions
      person.save!
    end
    assert_equal 3, person.project_subscriptions.count
  end


  test "person's projects include direct projects and parent projects" do
    parent_proj = Factory :project
    proj = Factory :project, :parent_id => parent_proj.id
    p = Factory(:brand_new_person, :work_groups => [Factory(:work_group, :project => proj)])
    assert_equal [parent_proj, proj].map(&:id).sort, p.projects.map(&:id).sort
  end

  test 'people subscribe to their projects and parent projects when their projects are assigned' do
      person = Factory(:brand_new_person)
      assert_equal 0, person.project_subscriptions.count
      work_group_ids  = [Factory(:work_group).id, Factory(:work_group).id ]

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

  test "subscribe/unsubscribe a project should subscribe/unsubscribe only itself rather that its parents" do
    add_project_subscriptions_attributes =  {"2"=>{"project_id"=> @proj_child1.id.to_s, "_destroy"=>"0", "frequency"=>"daily"}, "22"=>{"project_id"=>@proj_child2.id.to_s, "_destroy"=>"0", "frequency"=>"weekly"}}
    person = User.current_user.person
    assert_equal 0, person.project_subscriptions.count

    put "/people/#{person.id}", id: person.id, person:{"project_subscriptions_attributes"=> add_project_subscriptions_attributes}

    person.reload
    assert_equal 2, person.project_subscriptions.count

    remove_project_subscriptions_attributes =  {"2"=>{"id"=>person.project_subscriptions.first.id,"project_id"=> @proj_child1.id.to_s, "_destroy"=>"1", "frequency"=>"daily"}, "22"=>{"id"=>person.project_subscriptions.last.id, "project_id"=>@proj_child2.id.to_s, "_destroy"=>"1", "frequency"=>"weekly"}}
    put "/people/#{person.id}", id: person.id, person: {"project_subscriptions_attributes"=> remove_project_subscriptions_attributes}
    person.reload
    assert_equal 0, person.project_subscriptions.count
  end
  test "unassign a project will unsubscribe its parent projects unless the person also subscribes other sub-projects of the parent projects" do

    assert_equal 3, @person.project_subscriptions.count

    # unassign one child project of @proj,
    #subscription of @proj is not deleted as there is still another child project subscribed
    @person.work_groups.delete WorkGroup.where(:project_id=> @proj_child1.id).first
    disable_authorization_checks do
      @person.save
    end
    @person.reload
    assert_equal 2, @person.project_subscriptions.count

    #unassign all child projects
    @person.work_groups.delete WorkGroup.where(:project_id=> @proj_child2.id).first
    disable_authorization_checks do
      @person.save
    end
    @person.reload
    assert_equal 0, @person.project_subscriptions.count

  end

  test "clear all subscriptions when no project is assigned to person" do

    #subscribe an individual item in another project
    @person.subscriptions.build :subscribable => Factory(:subscribable)

    disable_authorization_checks do
      #save person in order to save built project subscriptions
      @person.save!
    end

    #@proj,@proj_child1,@proj_child2 are subscribed
    assert_equal 3, @person.project_subscriptions.count


    @person.project_subscriptions.each do |ps|
      ProjectSubscriptionJob.new(ps.id).perform
    end
    @person.reload
   # 3 subscriptions from project subscription for @proj + 1 individual subscription
    assert_equal 4, @person.subscriptions.count

    # unassign all related projects
    @person.work_groups.delete_all
   disable_authorization_checks do
      @person.save
   end
    @person.reload
    assert_equal 0, @person.project_subscriptions.count
    assert_equal 0, @person.subscriptions.count

  end


  test "admin defined roles in projects should be also the roles in sub projects" do
    assert_equal nil, @person.roles_mask

    #assign person with project with two children
    @person.work_groups.destroy_all
    @person.work_groups.create :project => @proj, :institution => Factory(:institution)
    disable_authorization_checks do
      @person.save!
    end
    @person.reload
    assert_equal [@proj, @proj_child1, @proj_child2], @person.projects_and_descendants

    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal false, @person.is_asset_manager?(p)
      assert_equal false, @person.is_project_manager?(p)
      assert_equal false, @person.is_pal?(p)
      assert_equal false, @person.is_gatekeeper?(p)

      assert p.asset_managers.empty?
      assert p.project_managers.empty?
      assert p.pals.empty?
      assert p.gatekeepers.empty?
    end


    @person.roles = [["asset_manager", @proj.id.to_s], ["project_manager", @proj.id.to_s], ["pal", @proj.id.to_s], ["gatekeeper", @proj.id.to_s]]
    disable_authorization_checks do
      @person.save!
    end
    @person.reload

    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal true, @person.is_asset_manager?(p)
      assert_equal true, @person.is_project_manager?(p)
      assert_equal true, @person.is_pal?(p)
      assert_equal true, @person.is_gatekeeper?(p)

      assert_equal [@person], p.asset_managers
      assert_equal [@person], p.project_managers
      assert_equal [@person], p.pals
      assert_equal [@person], p.gatekeepers
    end

    # test assigning roles to admins
    @person.roles_mask = Person.mask_for_role("admin")
    disable_authorization_checks do
      @person.save!
    end
    @person.reload
    assert @person.is_admin?

    @person.roles = [["asset_manager", @proj.id.to_s]]
    disable_authorization_checks do
      @person.save!
    end
    @person.reload
    assert @person.is_admin?
    [@proj, @proj_child1, @proj_child2].each do |p|
      assert_equal true, @person.is_asset_manager?(p)
      assert_equal [@person], p.asset_managers
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