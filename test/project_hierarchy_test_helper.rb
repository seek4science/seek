module ProjectHierarchyTestHelper
  def skip_hierarchy_tests?
    # MERGENOTE - skipping
    skip('skipping hierarchical project tests') unless Seek::Config.project_hierarchy_enabled
  end

  # perform delayed jobs when they are created for easy test
  def sync_delayed_jobs(delayed_job_classes = [])
    eval <<-END_EVAL
        class << Delayed::Job
              alias_method :enqueue_not_perform, :enqueue
              def enqueue(*args)
                   obj ||= args.shift
                  obj.perform if #{delayed_job_classes}.detect{|job_class| obj.is_a? job_class}
              end
          end
    END_EVAL
  end

  def desync_delayed_jobs
    eval <<-END_EVAL
      class << Delayed::Job
        alias_method :enqueue_perform, :enqueue
        alias_method :enqueue, :enqueue_not_perform
      end
    END_EVAL
  end

  def setup
    skip_hierarchy_tests?
    initialize_hierarchical_projects
  end

  def reload_extended_models
    [Project, Person, Assay, Study].each do |klass|
      force_reload_model klass.name
    end

    force_reload_model Seek::ProjectAssociation.name, "#{Rails.root}/lib/project_association.rb"

    Seek.send(:remove_const, 'AdminDefinedRoles')
    load "#{Rails.root}/lib/seek/admin_defined_roles.rb"
  end

  def force_reload_model(model_name, path = nil)
    model_path = path.nil? ? "#{Rails.root}/app/models/#{model_name.underscore}.rb" : path

    Object.send(:remove_const, model_name)
    load model_path
  end

  def login_as_test_user
    User.current_user = Factory(:user, login: 'test')
    # test actions in controller with User.current_user not nil
    post '/session', params: { login: 'test', password: generate_user_password }
  end

  def initialize_hierarchical_projects
    @proj = Factory(:project, title: 'parent project')
    @proj_child1 = Factory :project, title: 'child1 project', parent_id: @proj.id
    @proj_child2 = Factory :project, title: 'child2 project', parent_id: @proj.id
    person = Factory(:person, project:@proj)
    person.add_to_project_and_institution(@proj_child1,person.institutions.first)
    person.add_to_project_and_institution(@proj_child2,person.institutions.first)

    other_projects = (0..2).collect do
      p = Factory(:project)
      person.add_to_project_and_institution(p,person.institutions.first)
      p
    end

    @subscribables_in_proj = [Factory(:subscribable, projects: [other_projects[0], @proj], contributor:person),
                              Factory(:subscribable, projects: [@proj, other_projects[1],other_projects[2]], contributor:person),
                              Factory(:subscribable, projects: [@proj], contributor:person)]
  end

  def new_person_with_hierarchical_projects
    person = Factory(:brand_new_person)
    # add 2 work_groups directly
    person.work_groups.create project: @proj_child1, institution: Factory(:institution)
    person.work_groups.create project: @proj_child2, institution: Factory(:institution)
    disable_authorization_checks do
      # save person in order to save built project subscriptions
      person.save!
    end
    person.reload

    person
  end

  def current_person
    User.current_user.person
  end
end
