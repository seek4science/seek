
class Investigation < ActiveRecord::Base    
  acts_as_isa
  acts_as_authorized


  attr_accessor :new_link_from_study

  has_many :studies


  validates_presence_of :projects
  validates_presence_of :title

  has_many :assays,:through=>:studies

  searchable do
    text :description,:title
  end if Seek::Config.solr_enabled

  def can_delete? *args
    studies.empty? && super
  end
  
  #FIXME: see comment in Assay about reversing these
  ["data_file","sop","model"].each do |type|
    eval <<-END_EVAL
      def #{type}_masters
        studies.collect{|study| study.send(:#{type}_masters)}.flatten.uniq
      end

      def #{type}s
        studies.collect{|study| study.send(:#{type}s)}.flatten.uniq
      end

      #related items hash will use data_file_masters instead of data_files, etc. (sops, models)
      def related_#{type.pluralize}
        #{type}_masters
      end
    END_EVAL
  end

  def sops
    assays.collect{|assay| assay.sops}.flatten.uniq
  end

  def clone_with_associations
    new_object= self.clone
    new_object.policy = self.policy.deep_copy
    new_object.project_ids= self.project_ids
    return new_object
  end

end
