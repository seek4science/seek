require 'acts_as_authorized'
class Event < ActiveRecord::Base
  has_and_belongs_to_many :data_files

  #belongs_to :project
  #belongs_to :contributor
  #belongs_to :policy
  acts_as_authorized

  validates_presence_of :title
  #validates_uniqueness_of :title

  #validates_is_url_string :url
  validates_format_of :url, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true



end
