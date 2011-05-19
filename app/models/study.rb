require 'acts_as_authorized'
class Study < ActiveRecord::Base  
  acts_as_isa

  # The following is basically the same as acts_as_authorized,
  # but instead of creating a project attribute, I use the existing one.
    alias_attribute :contributor, :person_responsible

    after_initialize :policy_or_default_if_new

    belongs_to :policy, :autosave => true

    class_eval do
      extend Acts::Authorized::SingletonMethods
    end
    include Acts::Authorized::InstanceMethods
  #end of acts_as_authorized stuff

  belongs_to :investigation
  
  has_many :assays
  
  has_one :project, :through=>:investigation

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

  def can_delete? user=nil
    assays.empty? && mixin_super(user)
  end


end
