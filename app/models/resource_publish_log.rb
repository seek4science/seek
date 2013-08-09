class ResourcePublishLog < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true #, :required_access => false
  belongs_to :culprit, :polymorphic => true #, :required_access => false

  NOT_YET_PUBLISH = 0
  WAITING_FOR_APPROVAL = 1
  PUBLISHED = 2
  UNPUBLISHED = 3
  REJECTED=4

  CONSIDERING_TIME = 3.months

  def self.add_log publish_state, resource, comment="", user=User.current_user
    ResourcePublishLog.create(
        :culprit => user,
        :resource=>resource,
        :publish_state=>publish_state,
        :comment=>comment)
  end

  def self.requested_approval_assets_for gatekeeper
    #FIXME: write tests for this method.
    resource_types = Seek::Util.authorized_types.select{|klass| klass.is_isa? || klass.first.try(:is_in_isa_publishable?) }.collect{|klass| klass.name}
    requested_approval_logs = ResourcePublishLog.includes(:resource).where(["publish_state=? AND resource_type IN (?) AND created_at >?",
                                                                              WAITING_FOR_APPROVAL, resource_types, CONSIDERING_TIME.ago])
    requested_approval_assets = requested_approval_logs.collect(&:resource)
    requested_approval_assets.select!{|asset| !asset.is_published?}
    requested_approval_assets.select!{|asset| gatekeeper.is_gatekeeper_of? asset}
    requested_approval_assets.uniq
  end
end
