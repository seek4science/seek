module Seek::ResearchObjects
  module Packaging
    def package_path(item = self, prefix = '')
      prefix = package_path(item.study, prefix) if item.is_a?(Assay)
      prefix = package_path(item.investigation, prefix) if item.is_a?(Study)

      prefix + package_path_fragment(item)
    end

    def package_path_fragment(item)
      "#{item.class.name.underscore.pluralize}/#{item.id}/"
    end

    def permitted_for_research_object?(item = self)
      if item.is_downloadable?
        item.can_download?(nil)
      else
        item.can_view?(nil)
      end
    end
  end
end
