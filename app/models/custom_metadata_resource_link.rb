class CustomMetadataResourceLink < ApplicationRecord
  belongs_to :custom_metadata
  belongs_to :resource, polymorphic: true

  after_destroy :remove_linked_custom_metadata

  def remove_linked_custom_metadata
    if resource_type == "CustomMetadata"
      CustomMetadata.find(resource_id).destroy
    end
  end

end
