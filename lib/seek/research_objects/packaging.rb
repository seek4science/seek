module Seek
  module ResearchObjects
    # A mixin to add some utility methods for items being included in a research object
    module Packaging
      # provides the path within the research object the item will be described. e.g.
      # for an assay it would be:
      # investigations/{investigation_id}/studies/{study_id}/assays{assay_id}/
      def research_object_package_path(parents = [])
        return ro_package_path_fragment if is_asset?

        paths = parents.map do |parent|
          ro_package_path_fragment(parent)
        end

        paths << ro_package_path_fragment(self)

        paths[1..-1].join # Remove the top-level path, as it should be mounted at "/"
      end

      def ro_package_path_fragment(item = self)
        ro_package_path_type_fragment(item) + '/' + ro_package_path_id_fragment(item) + '/'
      end

      def ro_package_path_type_fragment(item = self)
        item.class.name.underscore.pluralize
      end

      def ro_package_path_id_fragment(item = self)
        "#{item.id}-#{item.title[0..128].parameterize}"
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

      # the filename for research object when downloaded. Takes the form [type]-[id].ro.zip
      def research_object_filename(item = self)
        "#{item.class.name.underscore}-#{item.id}.ro.zip"
      end
    end
  end
end
