class Programme < ActiveRecord::Base
  attr_accessible :avatar_id, :description, :first_letter, :title, :uuid, :web_page

  acts_as_yellow_pages
  include BackgroundReindexing

  #associations
  has_many :projects

  #validations
  validates :title,:uniqueness=>true

  scope :default_order, order('title')

  #TODO: why wasn't this added to the BackgroundReindexing module?
  after_save :queue_background_reindexing if Seek::Config.solr_enabled

  searchable(:auto_index=>false) do
    text :title,:description
    text :projects do
      projects.compact.map(&:title)
    end
    text :institutions do
      institutions.compact.map(&:title)
    end
  end if Seek::Config.solr_enabled

  def people
    projects.collect{|p| p.people}.flatten.uniq
  end

  def institutions
    projects.collect{|p| p.institutions}.flatten.uniq
  end


end

