# extensions for hierarchical projects

# Project can be configured as hierarchical ba setting Seek::Config.project_hierarchy_enabled = true
# @project's direct parent is saved in additional parent_id column in projects table.
# Its ancestors and descendants are stored in another table named "projects_descendants".
# 1.Work_groups is hierarchical,
# e.g. projects:  A,A1,A1.1,A1.2,A2,A2.1,A2.2 ;institutions: in1,in2,in3.
# if in1 is added to A1.1, then work group(in1 <-> A1.1), and ancestor work groups(in1 <-> A1,in1 <-> A) will be created,
# but NO groups memberships will be created for ancestor work groups, so ancestor work groups has no people.
# 2.Project Subscriptions is hierarchical
# - subscribe projects and ancestors when assigned to projects
# - subscribe only project when person subscribe via editing the profile

module Seek
  module ProjectHierarchies
    module ProjectExtension
      extend ActiveSupport::Concern
      RELATED_RESOURCE_TYPES = %w(Investigation Study Assay DataFile Model Sop Publication Event Presentation Organism HumanDisease)

      included do
        include ActsAsCachedTree
        after_update :touch_for_hierarchy_updates
        # add institution to ancestor projects
        after_add_for_institutions << proc { |c, project, institution| project.create_ancestor_workgroups(institution) }
        after_add_for_ancestors << proc { |c, project, ancestor| project.add_project_subscriptions_for_subscriber(ancestor) }
        after_remove_for_ancestors << proc { |c, project, ancestor| project.remove_project_subscriptions_for_subscriber(ancestor) }

        # relate_things, in the project and descendants
        Project::RELATED_RESOURCE_TYPES.each do |type|
          define_method "related_#{type.underscore.pluralize}" do
            res = send "#{type.underscore.pluralize}"
            descendants.each do |descendant|
              res |= descendant.send("#{type.underscore.pluralize}")
            end
            res.compact
          end
        end

        # admin defined project roles, in the project and its ancestors
        Seek::Roles::ProjectRelatedRoles.role_names.each do |role|
          define_method "#{role.pluralize}" do
            self_and_ancestors = [self] + ancestors
            self_and_ancestors.map { |proj| proj.people_with_the_role(role) }.flatten.uniq
          end
        end
      end

      def touch_for_hierarchy_updates
        if changed_attributes.include? :parent_id
          Permission.where(contributor_type: 'Project',
                           contributor_id: ([id] + ancestors.map(&:id) + descendants.map(&:id))).each(&:touch)
          ancestors.each(&:touch)
          descendants.each(&:touch)
        end
      end

      def create_ancestor_workgroups(institution)
        parent.institutions << institution unless parent.nil? || parent.institutions.include?(institution)
      end

      def add_project_subscriptions_for_subscriber(ancestor)
        subscribers = project_subscriptions.includes(:person).map(&:person)
        subscribers.each do |person|
          person.project_subscriptions.where(project_id: ancestor.id).first_or_create
        end
      end

      def remove_project_subscriptions_for_subscriber(ancestor)
        subscribers = project_subscriptions.includes(:person).map(&:person)
        subscribers.each do |person|
          person.project_subscriptions.where(project_id: ancestor.id).first.try(:destroy)
        end
      end

      # people in the project and its descendants
      def people
        # TODO: look into doing this with a named_scope or direct query
        res = ([self] + descendants).collect { |proj| proj.work_groups.collect(&:people) }.flatten.uniq.compact
        res.sort_by { |a| (a.last_name.blank? ? a.name : a.last_name) }
      end

      # project role, in project and its descendants
      def pis
        pi_role = ProjectPosition.find_by_name('PI')
        projects = [self] + descendants
        people.select { |p| p.project_positions_of_project(projects).include?(pi_role) }
      end

      # project role, in the project and its descendants
      def project_coordinators
        coordinator_role = ProjectPosition.project_coordinator_position
        projects = [self] + descendants
        people.select { |p| p.project_positions_of_project(projects).include?(coordinator_role) }
      end

      def can_delete?(user = User.current_user)
        super(user) && children.empty?
      end
    end
  end
end