class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, polymorphic: true # , :required_access => false
  belongs_to :user # , :required_access => false

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3
  REJECTED = 4

  CONSIDERING_TIME = 3.months

  def self.add_log(publish_state, resource, comment = '', user = User.current_user)
    ResourcePublishLog.create(
      user: user,
      resource: resource,
      publish_state: publish_state,
      comment: comment
    )
  end

  def self.requested_approval_assets_for(gatekeeper)
    # FIXME: write tests for this method.
    requested_approval_logs = ResourcePublishLog.includes(:resource).where(['publish_state=?',
                                                                            WAITING_FOR_APPROVAL])
    requested_approval_assets = requested_approval_logs.collect(&:resource).compact
    requested_approval_assets.reject!(&:is_published?)
    requested_approval_assets.select! { |asset| gatekeeper.is_asset_gatekeeper_of? asset }
    requested_approval_assets.uniq
  end

  def self.waiting_approval_assets_for(user)
    waiting_approval_logs = ResourcePublishLog.includes(:resource).where(['publish_state=? AND user_id=?',
                                                                          WAITING_FOR_APPROVAL, user.id])
    waiting_approval_assets = waiting_approval_logs.collect(&:resource).compact
    waiting_approval_assets.reject!(&:is_published?)
    waiting_approval_assets.uniq
  end

end
