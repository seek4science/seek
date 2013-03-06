class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true
  belongs_to :culprit, :polymorphic => true

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3

  def self.add_publish_log publish_state, resource, user=User.current_user
    ResourcePublishLog.create(
        :culprit => user,
        :resource=>resource,
        :publish_state=>publish_state)
  end
end
