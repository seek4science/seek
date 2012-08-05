class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true
  belongs_to :culprit, :polymorphic => true

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3
end
