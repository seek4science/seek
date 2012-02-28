module Seek
  #A class to represent a ProjectFolder for an Assay, which takes on the title and description of the assay,
  # and is neither editable,deletable or an incoming folder
  class AssayFolder
    attr_reader :assay, :project,:children,:parent

    ["editable","deletable","incoming"].each do |m|
        define_method "#{m}?" do
          false
        end
      end

    def initialize assay,project
      raise Exception.new("Project does not match those related to the assay") unless assay.projects.include?(project)
      @assay = assay
      @project = project
      @parent=nil
      @children=[]
    end

    def self.assay_folders project
       assays = project.assays.select{|assay| assay.is_experimental? && assay.can_edit?}.collect do |assay|
         Seek::AssayFolder.new assay,project
       end
    end

    #assets that are authorized to be shown for the current user
    def authorized_assets
      assay.assets.select{|a| a.can_view?}.collect{|a| a.parent}
    end

    def title
      assay.title
    end

    def label
      "#{title} (#{@assay.assets.count})"
    end

    def description
      assay.description
    end

    def id
      "Assay_#{assay.id}"
    end

  end
end
