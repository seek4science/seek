require 'acts_as_authorized'
require 'acts_as_uniquely_identifiable'
require 'grouped_pagination'
class Event < ActiveRecord::Base
  has_and_belongs_to_many :data_files

  #belongs_to :project
  #belongs_to :contributor
  #belongs_to :policy
  acts_as_authorized
  acts_as_uniquely_identifiable
  grouped_pagination

  #FIXME: Move to Libs
  Array.class_eval do
    def contains_duplicates?
      self.uniq.size != self.size
    end
  end
  
  validate :validate_data_files
  def validate_data_files
    errors.add(:data_files, 'May only contain one association to each data file') if self.data_files.contains_duplicates?
  end

  validate :validate_end_date
  def validate_end_date
    errors.add(:end_date, "is before start date.") unless self.end_date.nil? || self.start_date.nil? || self.end_date > self.start_date
  end

  validates_presence_of :title
  validates_presence_of :start_date
  validates_presence_of :end_date
  #validates_uniqueness_of :title

  #validates_is_url_string :url
  validates_format_of :url, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  alias_attribute :data_file_masters, :data_files

  def show_contributor_avatars?
    false
  end

end
