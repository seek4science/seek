class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true #, :required_access => false
  belongs_to :culprit, :polymorphic => true #, :required_access => false

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3
  REJECTED=4


  def self.add_log publish_state, resource, comment="", user=User.current_user
    ResourcePublishLog.create(
        :culprit => user,
        :resource=>resource,
        :publish_state=>publish_state,
        :comment=>comment)
  end
end
