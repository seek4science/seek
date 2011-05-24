require 'acts_as_authorized'
class Study < ActiveRecord::Base  
  acts_as_isa

  belongs_to :investigation
  has_one :project, :through=>:investigation

  acts_as_authorized

  has_many :assays

  belongs_to :person_responsible, :class_name => "Person"


  validates_presence_of :investigation

  validates_uniqueness_of :title

  acts_as_solr(:fields=>[:description,:title]) if Seek::Config.solr_enabled

  def data_files
    assays.collect{|a| a.data_files}.flatten.uniq
  end
  
  def sops
    assays.collect{|a| a.sops}.flatten.uniq
  end

  def can_delete? *args
    assays.empty? && mixin_super(*args)
  end


end
