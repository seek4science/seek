require 'zip'

# Investigation "snapshot"
class Snapshot < ActiveRecord::Base

  belongs_to :resource, polymorphic: true
  has_one :content_blob, as: :asset, foreign_key: :asset_id

  before_create :set_snapshot_number
  after_save :reindex_parent_resource

  # Must quack like an asset version to behave with DOI code
  alias_attribute :parent, :resource
  alias_attribute :parent_id, :resource_id
  alias_attribute :version, :snapshot_number

  delegate :md5sum, :sha1sum, to: :content_blob

  validates :snapshot_number, :uniqueness => { :scope =>  [:resource_type, :resource_id] }

  acts_as_doi_mintable(proxy: :resource)
  acts_as_zenodo_depositable do |snapshot|
    snapshot.content_blob # The thing to be deposited
  end

  def to_param
    snapshot_number.to_s
  end

  def metadata
    @ro_metadata ||= parse_metadata
  end

  def title
    metadata['title']
  end

  def description
    metadata['description']
  end

  def contributor
    Person.find(metadata['contributor']['uri'].match(/people\/([1-9][0-9]*)/)[1])
  end

  def creators
    if metadata['creators']
      metadata['creators'].map do |contributor|
        Person.find_by_id(contributor['uri'].match(/people\/([1-9][0-9]*)/)[1])
      end
    else
      []
    end
  end

  def related_people
    ([contributor] + creators).uniq
  end

  def all_related_people(node = metadata)
    people = []

    node.each do |k, v|
      if k == 'contributor'
        people << Person.find_by_id(v['uri'].match(/people\/([1-9][0-9]*)/)[1])
      elsif k == 'creators'
        people |= v.map { |p| Person.find_by_id(p['uri'].match(/people\/([1-9][0-9]*)/)[1]) }
      elsif v.is_a?(Hash)
        people |= all_related_people(v)
      elsif v.is_a?(Array)
        people |= v.map { |n| all_related_people(n) if n.is_a?(Hash) }.flatten
      end
    end

    people.uniq.compact
  end

  def research_object
    ROBundle::File.open(content_blob.filepath) do |ro|
      yield ro if block_given?
    end
  end

  def can_mint_doi?
    Seek::Config.doi_minting_enabled &&
         (resource.created_at + (Seek::Config.time_lock_doi_for || 0).to_i.days) <= Time.now
  end

  private

  def set_snapshot_number
    self.snapshot_number ||= (resource.snapshots.maximum(:snapshot_number) || 0) + 1
  end

  def doi_target_url
    polymorphic_url([resource, self],
                    :host => Seek::Config.host_with_port,
                    :protocol => Seek::Config.host_scheme)
  end

  def parse_metadata
    Seek::ResearchObjects::SnapshotParser.new(research_object).parse
  end

  # Need to re-index the parent model to update its' "doi" field
  def reindex_parent_resource
    ReindexingJob.new.add_items_to_queue(self.resource) if self.doi_changed?
  end

end
