module Seek
  module ProjectHierarchies
    module ItemsProjectsExtension
      def self.included(mod_or_class)
        mod_or_class.send :include, ExtendedMethods
      end
      module ExtendedMethods
        def related_projects
          projects_and_ancestors
        end

        def projects_and_ancestors
          projects.collect { |proj| [proj] + proj.ancestors }.flatten.uniq
        end

        def projects_and_descendants
          projects.collect { |proj| [proj] + proj.descendants }.flatten.uniq
        end
      end
    end
  end
end
