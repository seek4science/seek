# represents the details to connect to an openbis space
class OpenbisEndpoint < ActiveRecord::Base
  belongs_to :project
  belongs_to :policy, autosave: true
  attr_encrypted :password, key: :password_key

  has_many :external_assets, as: :seek_service # , dependent: :destroy

  validates :as_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :dss_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :web_endpoint, url: { allow_nil: true, allow_blank: true }
  validates :project, :as_endpoint, :dss_endpoint, :web_endpoint, :username,
            :password, :space_perm_id, :refresh_period_mins, :policy, presence: true
  validates :refresh_period_mins, numericality: { greater_than_or_equal_to: 60 }
  validates :space_perm_id, uniqueness: { scope: %i[dss_endpoint as_endpoint space_perm_id project_id],
                                          message: 'the endpoints and the space must be unique for this project' }

  after_create :create_refresh_metadata_job
  after_destroy :clear_metadata_store, :remove_refresh_metadata_job
  after_initialize :default_policy, autosave: true

  after_initialize :add_meta_config, autosave: true
  before_save :meta_config_to_json


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

  def refresh_metadata
    if test_authentication
      Rails.logger.info("REFRESHING METADATA FOR Openbis Space #{id}")

      clear_metadata_store
      #reindex_entities
      mark_for_refresh
      OpenbisSyncJob.new(self).queue_job
    else
      Rails.logger.info("Authentication test for Openbis Space #{id} failed, so not refreshing METADATA")
    end
  end

  #def reindex_entities
  #  # ugly should reindex only those that have changed
  #  datafiles = registered_datafiles
  #  ReindexingJob.new.add_items_to_queue datafiles unless datafiles.empty?
  #end

  def registered_datafiles
    # ugly will scan all content blobs from data files
    url = "openbis:#{id}"
    DataFile.all.select { |df| df.content_blob && df.content_blob.url && df.content_blob.url.start_with?(url) }
  end

  def registered_studies
    Study.joins(:external_asset).where(external_assets: { seek_service_id: id, seek_service_type: self.class })
  end

  def registered_assays
    Assay.joins(:external_asset).where(external_assets: { seek_service_id: id, seek_service_type: self.class })
  end

  def registered_datasets
    DataFile.joins(:external_asset).where(external_assets: { seek_service_id: id, seek_service_type: self.class })
  end

  def clear_metadata_store
    if test_authentication
      Rails.logger.info("CLEARING METADATA STORE FOR Openbis Space #{id}")
      metadata_store.clear
    else
      Rails.logger.info("Authentication test for Openbis Space #{id} failed, so not deleting METADATA STORE")
    end
  end

  def create_refresh_metadata_job
    OpenbisEndpointCacheRefreshJob.new(self).queue_job
  end

  def remove_refresh_metadata_job
    OpenbisEndpointCacheRefreshJob.new(self).delete_jobs
  end

  def associated_content_blobs
    ContentBlob.for_openbis_endpoint(self)
  end

  def default_policy
    self.policy = Policy.default if new_record? && policy.nil?
  end

  def add_meta_config
    self.meta_config = self.class.default_meta_config if new_record? && meta_config_json.nil? && @meta_config.nil?
  end

  def self.default_meta_config
    studies = ['DEFAULT_EXPERIMENT']
    assays = ['EXPERIMENTAL_STEP']
    build_meta_config(studies, assays)
  end

  def self.build_meta_config(studies, assays)
    studies ||= []
    assays ||= []
    raise 'table with types names expected' unless (studies.is_a?(Array) && assays.is_a?(Array))
    { study_types: studies, assay_types: assays }
  end

  def parse_code_names(names)

    names ||= ''
    names.upcase
        .split(/[,\s]/)
        .reject { |w| w.empty? }
        .uniq
  end

  def study_types
    meta_config[:study_types] || []
  end

  def study_types=(types)
    types = parse_code_names(types) if types.is_a? String
    raise 'table with types names expected' unless types.is_a? Array
    meta_config[:study_types] = types
  end

  def assay_types
    meta_config[:assay_types] || []
  end

  def assay_types=(types)
    types = parse_code_names(types) if types.is_a? String
    raise 'table with types names expected' unless types.is_a? Array
    meta_config[:assay_types] = types
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

  def mark_for_refresh
    due_to_refresh.update_all(sync_state: ExternalAsset.sync_states[:refresh])
  end

  def due_to_refresh
    old = DateTime.now - refresh_period_mins.minutes
    external_assets.synchronized.where("synchronized_at < ?", old)
  end


  private

  def meta_config_to_json
    self.meta_config_json = @meta_config.to_json if @meta_config # update only if local variable set
  end

  def meta_config
    @meta_config ||= self.meta_config_json ? JSON.parse(self.meta_config_json).symbolize_keys : { study_types: [], assay_types: [] }
    @meta_config
  end

  def meta_config=(config)
    # self.meta_config_json = config.to_json
    @meta_config = config
  end

end
