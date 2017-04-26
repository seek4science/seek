class Event < ActiveRecord::Base
  has_and_belongs_to_many :data_files, -> { uniq }
  has_and_belongs_to_many :publications, -> { uniq }
  has_and_belongs_to_many :presentations, -> { uniq }

  include Seek::Subscribable
  include Seek::Search::CommonFields
  include Seek::Search::BackgroundReindexing

  scope :default_order, -> { order('start_date DESC') }

  searchable(ignore_attribute_changes_of: [:updated_at], auto_index: false) do
    text :address, :city, :country, :url
  end if Seek::Config.solr_enabled

  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable

  # load the configuration for the pagination
  grouped_pagination

  # FIXME: Move to Libs
  Array.class_eval do
    def contains_duplicates?
      uniq.size != size
    end
  end

  validate :validate_data_files
  def validate_data_files
    errors.add(:data_files, 'May only contain one association to each data file') if data_files.contains_duplicates?
  end

  validate :validate_end_date
  def validate_end_date
    errors.add(:end_date, 'is before start date.') unless end_date.nil? || start_date.nil? || end_date >= start_date
  end

  validates_presence_of :title
  validates_presence_of :start_date

  # validates_is_url_string :url
  validates :url, url: {allow_nil: true, allow_blank: true}

  def show_contributor_avatars?
    false
  end

  # defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.events_enabled
  end
end
