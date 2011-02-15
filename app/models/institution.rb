require 'grouped_pagination'
require 'acts_as_yellow_pages'
require 'title_trimmer'

class Institution < ActiveRecord::Base

  title_trimmer

  acts_as_yellow_pages

  grouped_pagination :default_page => Seek::ApplicationConfiguration.default_page(:institutions)

  validates_uniqueness_of :name

  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  
  has_many :work_groups, :dependent => :destroy
  has_many :projects, :through=>:work_groups

  acts_as_solr(:fields => [ :name,:country,:city ]) if SOLR_ENABLED
  
  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    #TODO: write a test to check they are ordered
    return res.sort{|a,b| a.last_name <=> b.last_name}
  end  
  
  # get a listing of all known institutions
  def self.get_all_institutions_listing
    institutions = Institution.find(:all)
    return institutions.collect { |i| [i.name, i.id] }
  end  
  
end
