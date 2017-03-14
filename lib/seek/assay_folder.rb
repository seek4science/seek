module Seek
  # A class to represent a ProjectFolder for an Assay, which takes on the title and description of the assay,
  # and is neither editable,deletable or an incoming folder
  class AssayFolder
    attr_reader :assay, :project, :children, :parent

    %w(editable deletable incoming).each do |m|
      define_method "#{m}?" do
        false
      end
    end

    def initialize(assay, project)
      fail Exception.new("#{t('project')} does not match those related to the #{t('assays.assay').downcase}") unless assay.projects.include?(project)
      @assay = assay
      @project = project
      @parent = nil
      @children = []
    end

    def self.assay_folders(project)
      assays = project.assays.select { |assay| assay.is_experimental? && assay.can_edit? }.collect do |assay|
        Seek::AssayFolder.new assay, project
      end
    end

    def assets
      assay.assets | assay.publications
    end

    # assets that are authorized to be shown for the current user
    def authorized_assets
      assets.select(&:can_view?)
    end

    def title
      assay.title
    end

    def label
      "#{title} (#{assets.count})"
    end

    def description
      assay.description
    end

    def id
      "Assay_#{assay.id}"
    end

    def move_assets(assets, _src_folder)
      assets = Array(assets)
      assets.each do |asset|
        if asset.is_a?(Publication)
          Relationship.create subject: assay, other_object: asset, predicate: Relationship::RELATED_TO_PUBLICATION
        else
          assay.associate(asset)
        end
      end
    end

    def remove_assets(assets)
      assets = Array(assets)
      to_keep = []
      assay.assay_assets.each do |aa|
        aa.destroy if assets.include?(aa.asset)
      end
      assay.relationships.each do |rel|
        rel.destroy if assets.include?(rel.other_object)
      end
    end
  end
end
