class Event < ApplicationRecord
  has_and_belongs_to_many :data_files, -> { distinct }
  has_and_belongs_to_many :publications, -> { distinct }
  has_and_belongs_to_many :presentations, -> { distinct }
  has_and_belongs_to_many :documents, -> { distinct }

  before_destroy {documents.clear}

  before_save :set_timezone

  enforce_authorization_on_association :documents, :view

  include Seek::Subscribable
  include Seek::Search::CommonFields
  include Seek::Search::BackgroundReindexing
  include Seek::BioSchema::Support
  include Seek::Collectable

  searchable(ignore_attribute_changes_of: [:updated_at], auto_index: false) do
    text :address, :city, :country, :url
  end if Seek::Config.solr_enabled

  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable
  has_extended_metadata

  # load the configuration for the pagination
  grouped_pagination

  auto_strip_attributes :url

  validates_presence_of :title
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }
  validates_presence_of :start_date

  # validates_is_url_string :url
  validates :url, url: {allow_nil: true, allow_blank: true}

  validates :country, country:true, allow_blank: true

  has_filter :country
  has_filter start_date: Seek::Filtering::DateFilter.new(field: :start_date)

  validate :validate_data_files
  def validate_data_files
    df = data_files.to_a
    errors.add(:data_files, 'May only contain one association to each data file') unless (df.count == df.uniq.count)
  end

  validate :validate_end_date
  def validate_end_date
    errors.add(:end_date, 'is before start date.') unless end_date.nil? || start_date.nil? || end_date >= start_date
  end

  validate :validate_time_zone 
  def validate_time_zone
    errors.add(:time_zone, 'is not valid.') unless time_zone_valid?
  end

  def show_contributor_avatars?
    false
  end

  def self.user_creatable?
    Seek::Config.events_enabled
  end

  def self.can_create?
    Seek::Config.events_enabled && User.logged_in_and_member?
  end

  def time_zone_valid?
    time_zone.blank? || (ActiveSupport::TimeZone.all.map { |t| t.tzinfo.name }.include? time_zone)
  end

  def set_timezone
    return unless time_zone.present? && time_zone_valid?

    if start_date.present? && (start_date_changed? || time_zone_changed?)
      self.start_date = start_date.to_s(:db).in_time_zone(time_zone)
    end
    if end_date.present? && (end_date_changed? || time_zone_changed?)
      self.end_date = end_date.to_s(:db).in_time_zone(time_zone)
    end
  end

end
