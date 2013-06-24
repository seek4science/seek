require 'grouped_pagination'
require 'title_trimmer'

class Institution < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  title_trimmer

  acts_as_yellow_pages

  default_scope order("#{table_name}.name")

  #load the configuration for the pagination
  grouped_pagination
  validates_uniqueness_of :name

  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true
  
  has_many :work_groups, :dependent => :destroy
  has_many :projects, :through=>:work_groups

  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :name,:country,:city
  end if Seek::Config.solr_enabled

  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    #TODO: write a test to check they are ordered
    return res.sort{|a,b| a.last_name <=> b.last_name}
  end

   def can_be_edited_by?(subject)
    subject == nil ? false : (subject.is_admin? ||
          (subject.can_edit_institutions? && self.people.include?(subject.person)) ||
          (subject.is_project_manager? && !(subject.person.projects & projects).empty?))
  end

  # get a listing of all known institutions
  def self.get_all_institutions_listing
    Institution.all.collect { |i| [i.name, i.id] }
  end  
  
end
