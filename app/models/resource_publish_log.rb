class ResourcePublishLog < ApplicationRecord
  belongs_to :resource, polymorphic: true # , :required_access => false
  belongs_to :user # , :required_access => false

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3
  REJECTED = 4

  def self.add_log(publish_state, resource, comment = '', user = User.current_user)
    ResourcePublishLog.create(
      user: user,
      resource: resource,
      publish_state: publish_state,
      comment: comment
    )
  end

  def self.requested_approval_assets_for_gatekeeper(gatekeeper)
    # FIXME: write tests for this method.
    requested_approval_logs = ResourcePublishLog.includes(:resource).where(['publish_state=?', WAITING_FOR_APPROVAL])
    requested_approval_assets = requested_approval_logs.collect(&:resource).compact.uniq
    requested_approval_assets.select! { |asset| gatekeeper.is_asset_gatekeeper_of? asset }
    requested_approval_assets.sort_by{ |asset| asset.resource_publish_logs.last.created_at}.reverse!
  end

  def self.requested_approval_assets_for_user(user)
    requested_approval_logs = ResourcePublishLog.includes(:resource).where(['publish_state=? AND user_id=?', WAITING_FOR_APPROVAL, user.id])
    requested_approval_assets = requested_approval_logs.collect(&:resource).compact.uniq
    requested_approval_assets.sort_by{ |asset| asset.resource_publish_logs.last.created_at}.reverse!
  end

  def self.waiting_approval_assets(assets)
    assets.select { |asset| asset.last_publishing_log.try(:publish_state) == ResourcePublishLog::WAITING_FOR_APPROVAL }
  end

  def self.rejected_assets(assets)
    assets.select { |asset| asset.last_publishing_log.try(:publish_state) == ResourcePublishLog::REJECTED }
  end
end
