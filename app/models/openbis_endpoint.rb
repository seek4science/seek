# represents the details to connect to an openbis space
class OpenbisEndpoint < ActiveRecord::Base
  belongs_to :project
  belongs_to :policy, autosave: true
  attr_encrypted :password, key: :password_key

  validates :as_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :dss_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :web_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :project, :as_endpoint, :dss_endpoint, :web_endpoint, :username,
            :password, :space_perm_id, :refresh_period_mins, :policy, presence: true
  validates :refresh_period_mins, numericality: { greater_than_or_equal_to: 60 }
  validates :space_perm_id, uniqueness: { scope: %i[dss_endpoint as_endpoint space_perm_id project_id],
                                          message: 'the endpoints and the space must be unique for this project' }

  after_create :create_refresh_metadata_store_job
  after_destroy :clear_metadata_store, :remove_refresh_metadata_store_job
  after_initialize :default_policy, autosave: true

  def self.can_create?
    User.logged_in_and_member? && User.current_user.is_admin_or_project_administrator? && Seek::Config.openbis_enabled
  end

  def can_edit?(user = User.current_user)
    user && project.can_be_administered_by?(user) && Seek::Config.openbis_enabled
  end

  def can_delete?(user = User.current_user)
    can_edit?(user) && associated_content_blobs.empty?
  end

  def test_authentication
    !session_token.nil?
  rescue Fairdom::OpenbisApi::OpenbisQueryException
    false
  end

  def available_spaces
    Seek::Openbis::Space.new(self).all
  end

  # session token used for authentication, provided when logging in
  def session_token
    @session_token ||= Fairdom::OpenbisApi::Authentication.new(username, password, as_endpoint).login['token']
  end

  def space
    @space ||= Seek::Openbis::Space.new(self, space_perm_id)
  end

  def title
    "#{web_endpoint} : #{space_perm_id}"
  end

  def clear_metadata_store
    if test_authentication
      Rails.logger.info("CLEARING METADATA STORE FOR Openbis Space #{id}")
      metadata_store.clear
    else
      Rails.logger.info("Authentication test for Openbis Space #{id} failed, so not deleting METADATA STORE")
    end
  end

  def create_refresh_metadata_store_job
    OpenbisEndpointCacheRefreshJob.new(self).queue_job
  end

  def remove_refresh_metadata_store_job
    OpenbisEndpointCacheRefreshJob.new(self).delete_jobs
  end

  def associated_content_blobs
    ContentBlob.for_openbis_endpoint(self)
  end

  def default_policy
    self.policy = Policy.default if new_record? && policy.nil?
  end

  # this is necessary for the sharing form to include the project by default
  def projects
    [project]
  end

  def password_key
    Seek::Config.attr_encrypted_key
  end

  def metadata_store
    @metadata_store ||= Seek::Openbis::OpenbisMetadataStore.new(self)
  end
end
