class ToolAnnotation < ApplicationRecord
  belongs_to :resource, polymorphic: true, inverse_of: :tool_annotations

  validates_presence_of :bio_tools_id, :name
end
