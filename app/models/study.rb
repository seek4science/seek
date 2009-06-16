class Study < ActiveRecord::Base

  belongs_to :investigation
  has_many :assays
  
  has_one :project, :through=>:investigation

  has_many :data_files,:through=>:assays
  
  belongs_to :person_responsible, :class_name => "Person"

  validates_presence_of :title
  validates_presence_of :investigation

  validates_uniqueness_of :title

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED

  def sops
    sops=[]
    assays.each do |a|
      a.sops.each do |s|
        sops << s unless sops.include?(s)
      end
    end
    return sops
  end

  def can_edit? user
    user.person && user.person.projects.include?(project)
  end

  def can_delete? user
    assays.empty? && can_edit?(user)
  end


end
