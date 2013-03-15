class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true, :required_access => false
  belongs_to :culprit, :polymorphic => true, :required_access => false

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

  def self.last_waiting_approval_log resource, user=User.current_user
    latest_unpublished_log =  ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=? AND publish_state=?",
                                                                      resource.class.name, resource.id, ResourcePublishLog::UNPUBLISHED])
    if latest_unpublished_log.nil?
      ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=? AND culprit_type=? AND culprit_id=? AND publish_state=?",
                                              resource.class.name,resource.id, user.class.name, user.id, WAITING_FOR_APPROVAL])
    else
      ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=? AND culprit_type=? AND culprit_id=? AND publish_state=? AND created_at >?",
                                              resource.class.name,resource.id, user.class.name, user.id, WAITING_FOR_APPROVAL, latest_unpublished_log.created_at])
    end
  end

end
