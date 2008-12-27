require 'acts_as_editable'

class Institution < ActiveRecord::Base
  
  acts_as_editable
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_associated :avatars
  has_many :avatars, 
           :as => :owner,
           :dependent => :destroy
  
  has_many :work_groups, :dependent => :destroy
  has_many :projects, :through=>:work_groups
  
  #validates_presence_of :name, :country
  acts_as_solr(:fields => [ :name ]) if SOLR_ENABLED
  
  def people
    res=[]
    work_groups.each do |wg|
      wg.people.each {|p| res << p unless res.include? p}
    end
    return res
  end
  
  # "false" returned by this helper method won't mean that no avatars are uploaded for this institution;
  # it rather means that no avatar (other than default placeholder) was selected for the institution 
  def avatar_selected?
    return !avatar_id.nil?
  end
  
end
