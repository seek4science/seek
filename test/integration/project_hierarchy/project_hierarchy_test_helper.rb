module ProjectHierarchyTestHelper

  def login_as_test_user
    User.current_user = Factory(:user, :login => 'test')
    #test actions in controller with User.current_user not nil
    post '/session', :login => 'test', :password => 'blah'
  end

  def initialize_hierarchical_projects
    @proj = Factory(:project, :title => "parent project")
    @proj_child1 = Factory :project, :title => "child1 project", :parent => @proj
    @proj_child2 = Factory :project, :title => "child2 project", :parent => @proj
    @subscribables_in_proj = [Factory(:subscribable, :projects => [Factory(:project), @proj]),
                              Factory(:subscribable, :projects => [@proj, Factory(:project), Factory(:project)]),
                              Factory(:subscribable, :projects => [@proj])]
  end

  def new_person_with_hierarchical_projects
    person = Factory(:brand_new_person)
    #add 2 work_groups directly
    person.work_groups.create :project => @proj_child1, :institution => Factory(:institution)
    person.work_groups.create :project => @proj_child2, :institution => Factory(:institution)
    disable_authorization_checks do
      #save person in order to save built project subscriptions
      person.save!
    end
    person.reload

    person
  end

  #perform delayed jobs when they are created for easy test
  def sync_delayed_jobs
    Delayed::Job.class_eval do
      def self.enqueue(*args)
        obj = args.shift
        #puts "Delayed job #{obj.inspect}" unless obj.is_a? RdfGenerationJob
        obj.perform
      end
    end
  end

  def current_person
    User.current_user.person
  end


end