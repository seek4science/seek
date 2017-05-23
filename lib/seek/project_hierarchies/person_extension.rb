# override/add methods to Person
module Seek
  module ProjectHierarchies
    module PersonExtension
      def self.included(klass)
        klass.class_eval do
          after_add_for_work_groups << proc { |c, person, wg| person.subscribe_work_group_project_ancestors(wg) }
          after_remove_for_work_groups << proc { |c, person, wg| person.unsubscribe_work_group_project_ancestors(wg) }

          def subscribe_work_group_project_ancestors(wg)
            # subscribe parent projects
            wg.project.ancestors.each do |ancestor_proj|
              project_subscriptions.build project: ancestor_proj unless project_subscriptions.detect { |ps| ps.project_id == ancestor_proj.id }
            end
          end

          def unsubscribe_work_group_project_ancestors(wg)
            # unsubscirbe parent project subscriptions
            wg.project.ancestors.each do |ancestor_proj|
              ancestor_proj_sub = project_subscriptions.detect { |ps| ps.project_id == ancestor_proj.id }
              project_subscriptions.delete ancestor_proj_sub if ancestor_proj_sub && !ancestor_proj_sub.has_children?
            end
          end

          def direct_projects
            # updating work groups doesn't change group memberships until you save. And vice versa.
            work_groups.collect(&:project).uniq | group_memberships.collect { |gm| gm.work_group.project }
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
  end
end
