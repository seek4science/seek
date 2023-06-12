class CustomMetadataResourceLink < ApplicationRecord
  belongs_to :custom_metadata
  belongs_to :resource, polymorphic: true
end
