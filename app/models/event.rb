class Event < ApplicationRecord
  has_and_belongs_to_many :data_files, -> { distinct }
  has_and_belongs_to_many :publications, -> { distinct }
  has_and_belongs_to_many :presentations, -> { distinct }
  has_and_belongs_to_many :documents, -> { distinct }

  before_destroy {documents.clear}

  enforce_authorization_on_association :documents, :view

  include Seek::Subscribable
  include Seek::Search::CommonFields
  include Seek::Search::BackgroundReindexing
  include Seek::BioSchema::Support

  searchable(ignore_attribute_changes_of: [:updated_at], auto_index: false) do
    text :address, :city, :country, :url
  end if Seek::Config.solr_enabled

  acts_as_authorized
  acts_as_uniquely_identifiable
  acts_as_favouritable

  # load the configuration for the pagination
  grouped_pagination

  validate :validate_data_files
  def validate_data_files
    df = data_files.to_a
    errors.add(:data_files, 'May only contain one association to each data file') unless (df.count == df.uniq.count)
  end

  validate :validate_end_date
  def validate_end_date
    errors.add(:end_date, 'is before start date.') unless end_date.nil? || start_date.nil? || end_date >= start_date
  end

  validates_presence_of :title
  validates :title, length: { maximum: 255 }

  validates :description, length: { maximum: 65_535 }

  validates_presence_of :start_date

  # validates_is_url_string :url
  validates :url, url: {allow_nil: true, allow_blank: true}

  validates :country, country:true, allow_blank: true

  def show_contributor_avatars?
    false
  end

  # defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.events_enabled
  end
end
