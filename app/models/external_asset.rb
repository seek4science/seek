# Represents content from External Service like for example OpenBIS
# it provides basic features for tracking state, errors, and serialization
class ExternalAsset < ActiveRecord::Base
  self.inheritance_column = 'class_type'
  attr_accessor :sync_options, :content_changed

  enum sync_state: %i[synchronized refresh failed fatal]

  belongs_to :seek_entity, polymorphic: true
  belongs_to :seek_service, polymorphic: true

  has_one :content_blob, as: :asset, dependent: :destroy

  validates :external_id, uniqueness: { scope: :external_service }
  validates :external_service, uniqueness: { scope: :external_id }

  before_save :content_to_json
  before_save :save_content_blob
  before_save :options_to_json

  after_initialize :options_from_json

  after_save(:trigger_reindexing) if Seek::Config.solr_enabled

  # as there is no callback for reload
  def reload
    super
    options_from_json
  end

  def content=(content_object)
    json = serialize_content(content_object)
    self.content_changed = detect_change(content_object, json)

    @local_content = content_object
    @needs_serialization = true # serialization is postponed in case content would change externaly

    self.synchronized_at = DateTime.now
    self.sync_state = :synchronized
    self.err_msg = nil
    self.failures = 0
    self.external_mod_stamp = extract_mod_stamp(content_object)
    self.version = version ? version + 1 : 1
  end

  def content
    load_local_content unless @local_content
    @local_content
  end

  def add_failure(msg)
    self.sync_state = :failed unless fatal?
    self.failures += 1
    self.err_msg = msg || 'No message'
  end

  def serialize_content(content_object)
    return content_object.json if (defined? content_object.json) && content_object.json.is_a?(String)
    return content_object.json.to_json if (defined? content_object.json) && content_object.json.is_a?(Hash)
    return content_object.to_json if defined? content_object.to_json
    return content_object if content_object.is_a?(String)
    raise "Not implemented json serialization for external content class #{content_object.class}"
  end

  def deserialize_content(serial)
    return nil if serial.nil?
    JSON.parse serial
  end

  def load_local_content
    @local_content = deserialize_content(local_content_json)
  end

  def extract_mod_stamp(content_object)
    content_object.nil? ? '-1' : content_object.hash.to_s
  end

  def detect_change(content_object, _object_json)
    external_mod_stamp != extract_mod_stamp(content_object)
  end

  def content_to_json
    self.local_content_json = serialize_content(@local_content) if @needs_serialization
  end

  def init_content_holder
    return unless content_blob.nil?
    build_content_blob(url: (external_service ? external_service : '') + '#' + external_id,
                       content_type: 'application/json',
                       original_filename: external_id,
                       make_local_copy: false,
                       external_link: false)
  end

  def save_content_blob
    content_blob.save! unless content_blob.nil?
  end

  def options_to_json
    self.sync_options_json = @sync_options ? @sync_options.to_json : nil
  end

  def options_from_json
    @sync_options = sync_options_json ? JSON.parse(sync_options_json).symbolize_keys : {}
  end

  def needs_reindexing
    content_changed || external_mod_stamp_changed? || new_record?
  end

  def trigger_reindexing
    ReindexingJob.new.add_items_to_queue seek_entity if seek_entity && needs_reindexing
  end

  def search_terms
    []
  end

  protected

  def local_content_json=(content)
    raise 'Content must be a String' unless content.is_a? String
    init_content_holder
    content_blob.data = content
  end

  def local_content_json
    return nil if content_blob.nil? || content_blob.new_record?
    ans = content_blob.read
    content_blob.rewind
    ans
  end
end
