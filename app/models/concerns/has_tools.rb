module HasTools
  extend ActiveSupport::Concern

  included do
    has_many :tool_annotations, as: :resource, dependent: :destroy, autosave: true
  end

  def tools_attributes=(attributes)
    annotations = []

    attributes.each do |attrs|
      bio_tools_id = attrs[:bio_tools_id] || attrs['bio_tools_id']
      existing = tool_annotations.detect { |a| a.bio_tools_id == bio_tools_id }
      if existing
        annotations << existing.tap { |e| e.assign_attributes(attrs) }
      else
        annotations << tool_annotations.build(attrs)
      end
    end

    self.tool_annotations = annotations
  end
end
