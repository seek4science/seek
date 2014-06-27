module Seek
# Project can be configured as hierarchical by including this module.i.e.include Seek::ProjectHierarchies which should be at the end of Project model,
# @project's direct parent is saved in additional parent_id column in projects table.
# Its ancestors and descendants are stored in another table named "projects_descendants".
# 1.Work_groups is hierarchical,
# e.g. projects:  A,A1,A1.1,A1.2,A2,A2.1,A2.2 ;institutions: in1,in2,in3.
# if in1 is added to A1.1, then work group(in1 <-> A1.1), and ancestor work groups(in1 <-> A1,in1 <-> A) will be created,
# but NO groups memberships will be created for ancestor work groups, so ancestor work groups has no people.
# 2.Project Subscriptions is hierarchical

  module ProjectHierarchies

    def self.included klass
      klass.class_eval do
        include ActsAsCachedTree
        extend CallBackMethods

        after_add :institutions, :create_ancestor_workgroups

        after_update :touch_for_hierarchy_updates
        #when I have a new ancestor, subscribe to items in that project
        self.class_attribute :before_add_for_ancestors

        self.before_add_for_ancestors = Array.wrap(:add_indirect_subscriptions)

        def create_ancestor_workgroups institution
          parent.institutions << institution unless parent.nil? || parent.institutions.include?(institution)
        end



        def touch_for_hierarchy_updates
          if changed_attributes.include? :parent_id
            Permission.find_by_contributor_type("Project", :conditions => {:contributor_id => ([id] + ancestors.map(&:id) + descendants.map(&:id))}).each &:touch
            ancestors.each &:touch
            descendants.each &:touch
          end
        end

        def add_indirect_subscriptions ancestor
          subscribers = project_subscriptions.includes(:person).map(&:person)
          possibly_new_items = ancestor.subscribable_items #might already have subscriptions to these some other way
          subscribers.each do |p|
            possibly_new_items.each { |i| i.subscribe(p); disable_authorization_checks { i.save(false) } if i.changed_for_autosave? }
          end
        end


        def people
          #TODO: look into doing this with a named_scope or direct query
          res = ([self] + descendants).collect { |proj| proj.work_groups.collect(&:people) }.flatten.uniq.compact
          res.sort_by { |a| (a.last_name.blank? ? a.name : a.last_name) }
        end

        def project_coordinators
          coordinator_role = ProjectRole.project_coordinator_role
          projects = [self] + descendants
          people.select { |p| p.project_roles_of_project(projects).include?(coordinator_role) }

        end
        #
        ##this is the intersection of project role and seek role
        #def pals
        #  people_with_the_role("pal")
        #
        #  pal_role=ProjectRole.pal_role
        #  projects = [self] + descendants
        #  people.select { |p| p.is_pal? }.select do |possible_pal|
        #    possible_pal.project_roles_of_project(projects).include?(pal_role)
        #  end
        #end
        #
        #this is project role
        def pis
          pi_role = ProjectRole.find_by_name('PI')
          projects = [self] + descendants
          people.select { |p| p.project_roles_of_project(projects).include?(pi_role) }
        end


        Project::RELATED_RESOURCE_TYPES.each do |type|
          define_method "related_#{type.underscore.pluralize}" do
            res = send "#{type.underscore.pluralize}"
            descendants.each do |descendant|
              res = res | descendant.send("#{type.underscore.pluralize}")
            end
            res.compact
          end
        end

        def subscribable_items
          #TODO: Possibly refactor this. Probably the Project#subscribable_items should only return the subscribable items directly in _this_ project, not including its ancestors
          ProjectSubscription.subscribable_types.collect { |klass|
            if klass.reflect_on_association(:projects)
            then
              klass.scoped(:include => :projects)
            else
              klass.all
            end }.flatten.select { |item| !(([self] + ancestors) & item.projects).empty? }
        end

      end

      #override/add methods to Person
      Person.class_eval do
        def direct_projects
          #updating workgroups doesn't change groupmemberships until you save. And vice versa.
          work_groups.collect { |wg| wg.project }.uniq | group_memberships.collect { |gm| gm.work_group.project }
        end

        def projects
           direct_projects.collect { |proj| [proj] + proj.ancestors }.flatten.uniq
        end


        def projects_and_descendants
          direct_projects.collect { |proj| [proj] + proj.descendants }.flatten.uniq
        end
      end

    end


  end
  module CallBackMethods
     # dynamically add before_add callback to associations
    def before_add rel, callback
      a = reflect_on_association(rel)
      send(a.macro, rel, a.options.merge(:before_add => callback))
    end

    # dynamically add after_add callback to associations
    def after_add rel, callback
      a = reflect_on_association(rel)
      send(a.macro, rel, a.options.merge(:after_add => callback))
    end

    # dynamically add before_remove callback to associations
    def before_remove rel, callback
      a = reflect_on_association(rel)
      send(a.macro, rel, a.options.merge(:before_remove => callback))
    end
  end
end
