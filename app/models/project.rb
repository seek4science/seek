require 'acts_as_editable'

class Project < ActiveRecord::Base
  
  acts_as_editable
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_associated :avatars
  has_many :avatars, 
           :as => :owner,
           :dependent => :destroy
  
  has_many :work_groups, :dependent=>:destroy
  has_many :institutions, :through=>:work_groups

  acts_as_taggable_on :organisms
  
  acts_as_solr(:fields => [ :name ]) if SOLR_ENABLED
  
  def institutions=(new_institutions)
    new_institutions.each_index do |i|
      new_institutions[i]=Institution.find(new_institutions[i]) unless new_institutions.is_a?(Institution)
    end
    work_groups.each do |wg|
      wg.destroy unless new_institutions.include?(wg.institution)
    end
    for institution in new_institutions
      institutions << institution unless institutions.include?(institution)
    end
  end
  
  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    return res
  end
  
  # "false" returned by this helper method won't mean that no avatars are uploaded for this project;
  # it rather means that no avatar (other than default placeholder) was selected for the project 
  def avatar_selected?
    return !avatar_id.nil?
  end

  def includes_userless_people?
    peeps=people
    return peeps.size>0 && !(peeps.find{|p| p.user.nil?}).nil?
  end

  # Returns a list of projects that contain people that do not have users assigned to them
  def self.with_userless_people
    p=Project.find(:all, :include=>:work_groups)
    return p.select { |proj| proj.includes_userless_people? }
  end
  
end
