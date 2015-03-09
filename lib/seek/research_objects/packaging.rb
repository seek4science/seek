module Seek
  module ResearchObjects
    # A mixin to add some utility methods for items being included in a research object
    module Packaging
      # provides the path within the research object the item will be described. e.g.
      # for an assay it would be:
      # investigations/{investigation_id}/studies/{study_id}/assays{assay_id}/
      def research_object_package_path(item = self, prefix = '')
        prefix = research_object_package_path(item.study, prefix) if item.is_a?(Assay)
        prefix = research_object_package_path(item.investigation, prefix) if item.is_a?(Study)

        prefix + research_object_package_path_fragment(item)
      end

      def research_object_package_path_fragment(item)
        "#{item.class.name.underscore.pluralize}/#{item.id}/"
      end

      # whether an item is permitted to be included within a research objec
      # this is determined by whether it is downloadable (for a doablable asset)
      # or viewable, for a non downloadable item like ISA
      def permitted_for_research_object?(item = self)
        if item.is_downloadable?
          item.can_download?(nil)
        else
          item.can_view?(nil)
        end
      end
    end
  end
end
